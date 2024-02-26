project('cyantities', 'cpp', 'cython',
        default_options : ['optimization=3'])


#
# Include directory:
#
incdir = include_directories('cyantities/_cpp/')


#
# Dependencies:
#
boost_dep = dependency('boost')




#
# Find the NumPy headers here:
#
python = import('python').find_installation()
dep_py = python.dependency()

incpath_np = run_command(
  'gravelspoon',
  check : false
)
if incpath_np.returncode() != 0
    message(incpath_np.stdout().strip())
    message(incpath_np.stderr().strip())
    error('Could not determine NumPy include path.')
else
    incpath_np = incpath_np.stdout().strip()
endif

incdir_np = include_directories([incpath_np, incpath_np / '..' / '..' / '..'])

add_project_arguments(['-I' + incpath_np + '/../../../'], language : 'cython')
add_project_arguments(['-std=c++20','-Wall'], language : 'cpp')






#
# Static libraries:
#
libbackend = static_library(
    'backend',
    [
        'cyantities/_cpp/src/unit.cpp',
    ],
    dependencies : boost_dep,
    include_directories : incdir
)


#
# Python extension modules:
#
python.extension_module(
    'unit',
    'cyantities/unit.pyx',
    dependencies : [dep_py],
    include_directories : [incdir, incdir_np],
    override_options : ['cython_language=cpp'],
    link_with : libbackend
)

python.extension_module(
    'quantity',
    'cyantities/quantity.pyx',
    dependencies : [dep_py],
    include_directories : [incdir, incdir_np],
    override_options : ['cython_language=cpp'],
    link_with : libbackend
)