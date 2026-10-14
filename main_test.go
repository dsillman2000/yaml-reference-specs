package main

import "testing"

func TestNormalizeJSONNumbers(t *testing.T) {
	equal := [][2]string{
		{`{"Version": 1.0}`, `{"Version": 1}`},
		{`[1.50, -2.0, 0]`, `[1.5, -2, 0]`},
		{`{"big": 1e3}`, `{"big": 1000}`},
	}
	for _, c := range equal {
		if normalizeJSONNumbers(c[0]) != normalizeJSONNumbers(c[1]) {
			t.Errorf("expected %q and %q to normalize equal", c[0], c[1])
		}
	}

	different := [][2]string{
		// Numbers inside strings are not normalized
		{`{"Version": "1.0"}`, `{"Version": "1"}`},
		{`{"a\"1.0": 1}`, `{"a\"1": 1}`},
		// Numbers vs strings remain distinct
		{`{"Version": 1}`, `{"Version": "1"}`},
		{`{"Version": 1.5}`, `{"Version": 1}`},
		// Formatting and key order are still significant
		{`{"a": 1, "b": 2}`, `{"b": 2, "a": 1}`},
	}
	for _, c := range different {
		if normalizeJSONNumbers(c[0]) == normalizeJSONNumbers(c[1]) {
			t.Errorf("expected %q and %q to normalize differently", c[0], c[1])
		}
	}
}
