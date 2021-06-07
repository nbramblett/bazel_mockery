package testgo_test

import (
	"testing"

	"testgo/mocks"

	"github.com/stretchr/testify/mock"
)

func TestStringy(t *testing.T) {
	s := mocks.Stringy{mock.Mock{}}
	s.On("DoString", mock.Anything).Return("foo")
	str := s.DoString("fooble")
	if str != "foo" {
		t.Fatal("wrong string returned")
	}
}

func TestPrivateStringy(t *testing.T) {
	s := mocks.PrivateStringy{mock.Mock{}}
	s.On("DoString2", mock.Anything).Return("bar")
	str := s.DoString2("fooble")
	if str != "bar" {
		t.Fatal("wrong string returned")
	}
}
