#!/bin/vbash
#
# Install script to create/re-create symlinks for "l2tp-updown.sh"
#
# Copyright (c) 2016 Andrew Heberle
#
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
target="/config/scripts/l2tp-updown.sh"
if [ -f ${target} ]; then
	for a in up down; do
		linkname="/etc/ppp/ip-${a}.d/l2tp-${a}"
		# Check if link exists, remove it
		if [ -L ${linkname} ]; then
			echo "Warning: Existing link found at ${linkname}. Removing..."
			rm -f ${linkname}
		fi
		# Check if target exists
		if [ -f ${linkname} ]; then
			# File should not exist so we bail out
			echo "Error: File found at ${linkname}"
			break
		fi
		# Create link
		echo "Creating link at ${linkname}..."
		ln -s ${target} ${linkname}
	done
else
	echo "Error: ${target} does not exist."
	exit 1
fi
exit 0
