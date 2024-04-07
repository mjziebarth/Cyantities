# Build the parasolve code.
#
# Author: Malte J. Ziebarth (mjz.science@fmvkb.de)
#
# Copyright (C) 2024 Malte J. Ziebarth
#
# Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
# the European Commission - subsequent versions of the EUPL (the "Licence");
# You may not use this work except in compliance with the Licence.
# You may obtain a copy of the Licence at:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the Licence is distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Licence for the specific language governing permissions and
# limitations under the Licence.

import os
import glob
from shutil import copyfile
from pathlib import Path
from subprocess import run

#
# (1) Check where we are and where we need to go:
#
current = Path('.').resolve()
root = Path(__file__).resolve().parent

#
# (2) Meson build
#
os.chdir(root)
run(['meson','setup','builddir'])
os.chdir(root / "builddir")
run(['meson','compile'], check=True)

#
# (3) Copy the extension module:
#
# NOTE: This should not work on Windows.
# Probable fix: change the file extension to .dll
extname = glob.glob('parasolve*.so')[0]
os.chdir(root)
copyfile(root / "builddir" / extname, root / extname)