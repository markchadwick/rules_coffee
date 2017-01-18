coffee_src_type = FileType(['.coffee'])


def _coffee_compile_dir(ctx, dir, srcs):
  """
  Compiles a single directory of CoffeeScript files into JavaScript files. The
  compiler tries to infer a reasonable source root when dealing with input files
  from multiple directories, which would be incorrect here in all but the most
  pathological of cases.
  """
  out_dir   = ctx.configuration.bin_dir.path + '/' + dir
  outputs   = []
  arguments = [
    '--no-header',
    '--compile',
    '--output', out_dir,
  ]

  for src in srcs:
    js_name = src.basename.replace('.coffee', '.js')
    output  = ctx.new_file(js_name)

    arguments.append(src.path)
    outputs.append(output)

  ctx.action(
    mnemonic   = 'CompileCoffeeScript',
    executable = ctx.executable._csc,
    arguments  = arguments,
    inputs     = list(srcs + [ctx.executable._node]),
    outputs    = outputs,
  )

  return outputs


def coffee_compile(ctx, srcs):
  """
  Compiles a set of CoffeeScript sources in arbitrary directories to JavaScript.
  Groups source files by directory beforehand and invokes a compilation step for
  each source directory to keep the output sane.
  This, in practice, will still only be one compiler invocation for any module.
  """
  srcs_by_dir = {}
  for src in srcs:
    dir = src.dirname
    if dir not in srcs_by_dir:
      srcs_by_dir[dir] = set([src], order='compile')
    else:
      srcs_by_dir[dir] += [src]

  files = set(order='compile')
  for dir in srcs_by_dir:
    files += _coffee_compile_dir(ctx, dir, srcs_by_dir[dir])

  return struct(files=files)


def coffee_srcs_impl(ctx):
  return coffee_compile(ctx, ctx.files.srcs)

def coffee_src_impl(ctx):
  return coffee_compile(ctx, ctx.files.src)

# -----------------------------------------------------------------------------

attrs = {
  '_csc': attr.label(
    default    = Label('//coffee/toolchain:csc'),
    executable = True,
    cfg        = 'host'),
  '_node':  attr.label(
    default     = Label('@io_bazel_rules_js//js/toolchain:node'),
    cfg         = 'host',
    executable  = True,
    allow_files = True),
}

coffee_srcs = rule(
  coffee_srcs_impl,
  attrs = attrs + {
    'srcs': attr.label_list(allow_files=coffee_src_type),
  },
)

coffee_src = rule(
  coffee_src_impl,
  attrs = attrs + {
    'src': attr.label(allow_files=coffee_src_type),
  },
)
