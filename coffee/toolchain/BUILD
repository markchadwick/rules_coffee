load('@io_bazel_rules_js//js:def.bzl', 'js_binary')

js_binary(
  name = 'csc',
  src  = 'csc.js',
  deps = ['@coffee.script//:lib'],
  visibility = ['//visibility:public'],
)
