package testgo

import "fmt"

type Stringy interface {
	DoString(string) string
}

func DoTheStringThing(stringy Stringy, str string) {
	fmt.Println(stringy.DoString(str))
}

type privateStringy interface {
	DoString2(string) string
}

func DoTheStringThing2(stringy privateStringy, str string) {
	fmt.Println(stringy.DoString2(str))
}
