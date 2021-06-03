package testgo

import "fmt"

type Stringy interface {
	DoString(string) string
}

func DoTheStringThing(stringy Stringy, str string) {
	fmt.Println(stringy.DoString(str))
}
