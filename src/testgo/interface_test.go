package testgo_test

import (
	"testing"

	"testgo/mocks"

	"github.com/stretchr/testify/mock"
)

func TestStringer(t *testing.T) {
	s := mocks.Stringy{mock.Mock{}}
	s.On("DoString", mock.Anything).Return("foo")
	str := s.DoString("fooble")
	if str != "foo" {
		t.Fatal("wrong string returned")
	}
}
