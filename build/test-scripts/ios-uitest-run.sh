﻿#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

export NUNIT_VERSION=3.12.0

if [ "$UITEST_SNAPSHOTS_ONLY" == 'true' ];
then
	export SCREENSHOTS_FOLDERNAME=ios-Snap

	# CommandBar disabled: https://github.com/unoplatform/uno/issues/1955
	# runGroup is used to parallelize the snapshots tests on multiple agents
	export TEST_FILTERS=" \
		namespace == 'SamplesApp.UITests.Snap' \
		and Description !~ 'automated:Uno.UI.Samples.Content.UITests.CommandBar.*' \
		and Description =~ 'runGroup:$UITEST_SNAPSHOTS_GROUP' \
	"
else
	export SCREENSHOTS_FOLDERNAME=ios

	# Note for test authors, add tests in the last group, notify devops
	# notify devops when the group gets too big.
	# See https://github.com/unoplatform/uno/issues/1955 for additional details

	if [ "$UITEST_AUTOMATED_GROUP" == '1' ];
	then
		export TEST_FILTERS=" \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.ButtonTests' or \
			namespace = 'SamplesApp.UITests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Input.VisualState_Tests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.FlyoutTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.DatePickerTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.WUXProgressRingTests' or \
			class = 'SamplesApp.UITests.Windows_UI_Xaml.DragAndDropTests.DragDrop_ListViewReorder_Automated' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.ListViewTests' or \
			namespace = 'SamplesApp.UITests.MessageDialogTests'
		"
	elif [ "$UITEST_AUTOMATED_GROUP" == '2' ];
	then
		export TEST_FILTERS=" \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Media.Animation_Tests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.ControlTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.TextBlockTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.ImageTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml.FocusManagerDirectionTests' or \
			namespace = 'SamplesApp.UITests.Microsoft_UI_Xaml_Controls.NumberBoxTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.ItemsControl' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.TextBoxTests'
		"
	elif [ "$UITEST_AUTOMATED_GROUP" == '3' ];
	then
		export TEST_FILTERS=" \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.PivotTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.CommandBarTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.ComboBoxTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Media_Animation' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.BorderTests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.MenuFlyoutTests' or \
			class = 'SamplesApp.UITests.Windows_UI_Xaml_Shapes.Basics_Shapes_Tests' or \
			namespace = 'SamplesApp.UITests.Windows_UI_Xaml_Controls.ScrollViewerTests'
		"
	elif [ "$UITEST_AUTOMATED_GROUP" == '4' ];
	then
		export TEST_FILTERS=" \
			class = 'SamplesApp.UITests.Runtime.RuntimeTests'
		"
	elif [ "$UITEST_AUTOMATED_GROUP" == 'Benchmarks' ];
	then
		export TEST_FILTERS=" \
			class = 'SamplesApp.UITests.Runtime.BenchmarkDotNetTests'
		"
	fi
fi

export UNO_UITEST_PLATFORM=iOS
export UNO_UITEST_SCREENSHOT_PATH=$BUILD_ARTIFACTSTAGINGDIRECTORY/screenshots/$SCREENSHOTS_FOLDERNAME

export UNO_ORIGINAL_TEST_RESULTS=$BUILD_SOURCESDIRECTORY/build/TestResult-original.xml
export UNO_TESTS_FAILED_LIST=$BUILD_SOURCESDIRECTORY/build/uitests-failure-results/failed-tests-ios-$SCREENSHOTS_FOLDERNAME-${UITEST_SNAPSHOTS_GROUP=automated}-${UITEST_AUTOMATED_GROUP=automated}.txt
export UNO_TESTS_RESPONSE_FILE=$BUILD_SOURCESDIRECTORY/build/nunit.response
export UNO_TESTS_LOCAL_TESTS_FILE=$BUILD_SOURCESDIRECTORY/src/SamplesApp/SamplesApp.UITests/bin/Release/SamplesApp.UITests.dll
export UNO_UITEST_BENCHMARKS_PATH=$BUILD_ARTIFACTSTAGINGDIRECTORY/benchmarks/ios-automated
export UNO_UITEST_RUNTIMETESTS_RESULTS_FILE_PATH=$BUILD_SOURCESDIRECTORY/build/RuntimeTestResults-ios-automated.xml

if grep -q "invalid-test-for-retry" "$UNO_TESTS_FAILED_LIST";
then
	# The test results file only contains the re-run marker and no
	# other test to rerun. We can skip this run.
	echo "The file $UNO_TESTS_FAILED_LIST does not contain tests to re-run, skipping."
	exit 0
fi

echo "Current system date"
date

echo "Listing iOS simulators"
xcrun simctl list devices --json

## Preemptively start the simulator
/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/Contents/MacOS/Simulator &

## Pre-build the transform tool to get early warnings
pushd $BUILD_SOURCESDIRECTORY/src/Uno.NUnitTransformTool
dotnet build
popd

cd $BUILD_SOURCESDIRECTORY/build

mono nuget/nuget.exe install NUnit.ConsoleRunner -Version $NUNIT_VERSION

mkdir -p $UNO_UITEST_SCREENSHOT_PATH

# Imported app bundle from artifacts is not executable
chmod -R +x $UNO_UITEST_IOSBUNDLE_PATH

# Move to the screenshot directory so that the output path is the proper one, as
# required by Xamarin.UITest
cd $UNO_UITEST_SCREENSHOT_PATH

## Build the NUnit configuration file
echo "--trace=Verbose" > $UNO_TESTS_RESPONSE_FILE
echo "--result=$UNO_ORIGINAL_TEST_RESULTS" >> $UNO_TESTS_RESPONSE_FILE
echo "--timeout=$UITEST_TEST_TIMEOUT" >> $UNO_TESTS_RESPONSE_FILE

if [ -f "$UNO_TESTS_FAILED_LIST" ]; then
    echo "--testlist \"$UNO_TESTS_FAILED_LIST\"" >> $UNO_TESTS_RESPONSE_FILE
else
    echo "--where \"$TEST_FILTERS\"" >> $UNO_TESTS_RESPONSE_FILE
fi

if [ -f "$UNO_TESTS_LOCAL_TESTS_FILE" ]; then
	# used for local tests builds using the local-ios-uitest-run.sh script
	echo "$UNO_TESTS_LOCAL_TESTS_FILE" >> $UNO_TESTS_RESPONSE_FILE
else
	echo "$BUILD_SOURCESDIRECTORY/build/samplesapp-uitest-binaries/SamplesApp.UITests.dll" >> $UNO_TESTS_RESPONSE_FILE
fi

echo Response file:
cat $UNO_TESTS_RESPONSE_FILE

## Run NUnit tests
mono $BUILD_SOURCESDIRECTORY/build/NUnit.ConsoleRunner.$NUNIT_VERSION/tools/nunit3-console.exe \
    @$UNO_TESTS_RESPONSE_FILE \
	|| true

echo "Current system date"
date

# export the simulator logs
export LOG_FILEPATH=$UNO_UITEST_SCREENSHOT_PATH/_logs
export TMP_LOG_FILEPATH=/tmp/DeviceLog-`date +"%Y%m%d%H%M%S"`.logarchive

mkdir -p $LOG_FILEPATH
xcrun simctl spawn booted log collect --output $TMP_LOG_FILEPATH
log show --style syslog $TMP_LOG_FILEPATH > $LOG_FILEPATH/DeviceLog-$UITEST_AUTOMATED_GROUP-`date +"%Y%m%d%H%M%S"`.txt

## Export the failed tests list for reuse in a pipeline retry
pushd $BUILD_SOURCESDIRECTORY/src/Uno.NUnitTransformTool
mkdir -p $(dirname ${UNO_TESTS_FAILED_LIST})
dotnet run list-failed $UNO_ORIGINAL_TEST_RESULTS $UNO_TESTS_FAILED_LIST
popd
