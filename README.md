### DomainCertChecker

checks certificate validity periodically with an email to SRE on site reliability


## Usage:

Download the repo and Execute shell script.

`git clone git@github.com:MrSunny-M/DomainCertChecker.git`

must specify -f option with the name of the file that contains the list of sites to check

1. Launch the script in terminal mode

```bash
./certChecker.sh -f sitelist -o terminal
```

2. execute and export output to .html file

```bash
./certChecker.sh -f sitelist -o html
```

3. Using HTML mode and sending results via email

```bash
./certChecker.sh -f sitelist -o html -m example@mail.com
```

### Options

    -f [ sitelist file ]          list of sites (domains) to check
		-o [ html | terminal ]        output (can be html or terminal)
		-m [ mail ]                   mail address to send the graphs to
		-h                            help
    
    
## License

[MIT](https://choosealicense.com/licenses/mit/)

## Author

[Saikiran M](https://github.com/MrSunny-M)
