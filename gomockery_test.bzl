load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":gomockery.bzl", "interface_to_case")

def _interface_to_case_test_impl(ctx):
    env = unittest.begin(ctx)
    tests = [
        ("", ""),
        ("lowercase", "lowercase"),
        ("camelCase", "camel_case"),
        ("PascalCase", "pascal_case"),
        ("UPPERCASE", "uppercase"),
    ]

    for test in tests:
        input, expected = test[0], test[1]
        actual = interface_to_case(input)
        asserts.equals(env, expected, actual)

    return unittest.end(env)
interface_to_case_test = unittest.make(_interface_to_case_test_impl)

def gomockery_test_suite():
    unittest.suite(
        "gomockery_tests",
        interface_to_case_test,
    )