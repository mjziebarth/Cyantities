project('testing.test_backend', 'cpp', 'cython',
        default_options : ['optimization=3'])


#
# Dependencies:
#
cyantities_dep = dependency(
    'cyantities',
    fallback : ['cyantities', 'libcyantities_dep']
)


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

#
# Include directory:
#
incdir = include_directories(['.', incpath_np])

add_project_arguments(['-std=c++20','-Wall'], language : 'cpp')

#
# Finally compile the extension module:
#
python.extension_module(
    'test_backend',
    ['test_backend.pyx'],
    dependencies : [dep_py, cyantities_dep],
    include_directories : [incdir],
    override_options : ['cython_language=cpp']
)