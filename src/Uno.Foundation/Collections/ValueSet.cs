﻿#nullable enable
using System;
using System.Collections;
using System.Collections.Generic;

namespace Windows.Foundation.Collections;

public sealed partial class ValueSet : IPropertySet, IObservableMap<string, object?>, IDictionary<string, object?>, IEnumerable<KeyValuePair<string, object?>>
{
	private readonly Dictionary<string, object?> _dictionary = new();

	public ValueSet()
	{
	}

	public event MapChangedEventHandler<string, object?>? MapChanged;

	public void Add(string key, object? value)
	{
		_dictionary.Add(key, value);

		MapChanged?.Invoke(this, new MapChangedEventArgs(CollectionChange.ItemInserted, key));
	}

	public bool ContainsKey(string key)
		=> _dictionary.ContainsKey(key);

	public bool Remove(string key)
	{
		var result = _dictionary.Remove(key);

		if (result)
		{
			MapChanged?.Invoke(this, new MapChangedEventArgs(CollectionChange.ItemRemoved, key));
		}

		return result;
	}

	public bool TryGetValue(string key, out object? value)
	{
		if (key is null)
		{
			throw new ArgumentNullException("TryGetValue with null key");
		}
		return _dictionary.TryGetValue(key, out value);
	}

	public ICollection<string> Keys
		=> _dictionary.Keys;

	public ICollection<object?> Values
		=> _dictionary.Values;

	public void Add(KeyValuePair<string, object?> item)
		=> Add(item.Key, item.Value);

	public void Clear()
	{
		_dictionary.Clear();

		MapChanged?.Invoke(this, new MapChangedEventArgs(CollectionChange.Reset, null));
	}

	public bool Contains(KeyValuePair<string, object?> item)
	{
		object? value;
		if(!_dictionary.TryGetValue(item.Key, out value))
		{
			return false;
		}

		if (item.Value is null && value is null)
		{
			return true;
		}

		if (item.Value is null || value is null)
		{
			return false;
		}

		return item.Value.Equals(value);
	}

	public void CopyTo(KeyValuePair<string, object?>[] array, int arrayIndex)
	{
		if (array == null)
		{
			throw new ArgumentNullException("How can I copy elements to array when array is null?");
		}

		if(arrayIndex < 0)
		{
			throw new ArgumentOutOfRangeException("Cannot copy less than 0 elements");
		}

		// check now, before starting to copy elements
		if(array.GetUpperBound(0) - arrayIndex < Count)
		{
			throw new ArgumentException("Array is too small");
		}

		foreach(var item in _dictionary)
		{
			array[arrayIndex++] = item;
		}
	}

	public bool Remove(KeyValuePair<string, object?> item)
		=> Remove(item.Key);

	public int Count
		=> _dictionary.Count;

	// current implementation is always read/write
	public bool IsReadOnly => false;

	// auto-generated by VStudio, as required by IDictionary
	public object? this[string key]
	{
		get => _dictionary[key];
		set
		{
			var containsKey = _dictionary.ContainsKey(key);

			_dictionary[key] = value;

			MapChanged?.Invoke(
				this,
				new MapChangedEventArgs(
					containsKey ? CollectionChange.ItemChanged : CollectionChange.ItemInserted,
					key));
		}
	}

	public IEnumerator<KeyValuePair<string, object?>> GetEnumerator()
		=> _dictionary.GetEnumerator();

	IEnumerator IEnumerable.GetEnumerator()
		=> _dictionary.GetEnumerator();
}
