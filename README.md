# rclone-myrient

[![License](https://img.shields.io/badge/license-GPLv3-brightgreen.svg?style=flat)](COPYING)

A yaml controlled bash script to sync roms from myrient via rclone with custom filters

## Usage

    bash rclone-myrient.sh [options]

## Options

| Flag | Default                 | Description                         |
| ---- | ----------------------- | ----------------------------------- |
| -b   | /usr/bin/rclone         | Change path to rclone binary        |
| -c   | /etc/rclone/rclone.conf | Change path to rclone config        |
| -d   | false                   | Enable debugging output             |
| -f   | rclone-myrient.yaml     | Change path to script config yaml   |
| -s   | /usr/bin/shyaml         | Change path to shyaml binary        |
| -t   | copy                    | Change rclone transfer mechanism    |

## Examples

    bash rclone-myrient.sh -d
    bash rclone-myrient.sh -b ~/.local/bin/rclone -s /opt/homebrew/bin/shyaml  -d

## License

Copyright (C) 2025 Taylor Kimball

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
