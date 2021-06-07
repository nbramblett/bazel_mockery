package main

import (
	"fmt"

	"src/testgo"
)

func main() {
	testgo.DoTheStringThing(StringyConcrete{prefix: "pre-"}, "string")
}

type StringyConcrete struct {
	prefix string
}

func (s StringyConcrete) DoString(str string) string {
	return fmt.Sprintf("%s%s", s.prefix, str)
}
