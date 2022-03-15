# PowerDown (>'-')>

PowerDown is a super boring and straightforward static site generator written in `PowerShell`.
It copies content from one folder (`$contentFolder`) to an output folder (`$outputFolder`).
It also recognizes [`markdown`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertfrom-markdown?view=powershell-7.2) files and generates `html` files.
It runs in a continuous loop with a file watcher, so as you make changes to the `content` folder, they will be copied over.

## Installation

[Snag this repo](https://github.com/vandsh/powerdown) (download or clone it).

## Usage

- Open `powerdown.ps1` and update any necessary values (namely `outputFolder` and `contentFolder`)
- Change `template.html` to your liking
- Run `powerdown.ps1`

## Contributing
Pull requests are welcome.

## Future
Nothing planned, considering looking into using `GraphQL` to create static pages.

## References
- https://powershell.one/tricks/filesystem/filesystemwatcher
- https://github.com/markdowncss/retro/blob/master/index.html