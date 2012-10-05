linode-cli
==========

The purpose of this project is to provide a quick command line interface to common Linode administration tasks.

Currently, only the DNS module is in-place. This lets you view and manipulate A, AAAA, CNAME, MX, and TXT DNS records for any domain for which your Linode API key has access.

Usage examples:

 - Show all A DNS records for example.com:

        ./linode-cli.rb dns show a example.com

 - Show all DNS records for example.com:

        ./linode-cli.rb dns show example.com

 - Show all CNAME DNS records for all accessible domains:

        ./linode-cli.rb dns show cname

 - Show all DNS records for all accessible domains:

        ./linode-cli.rb dns show

 - Add an A DNS record named 'test' to example.com:
 
        ./linode-cli.rb dns add example.com test 192.168.1.3

 - Update an the IP for a A DNS record named 'test' at example.com:
 
        ./linode-cli.rb dns update example.com test 192.168.1.4

 - Delete an A DNS record named 'test' from example.com:
 
        ./linode-cli.rb dns del example.com test
 
Put a symlink in your `~/bin` directory named 'linode' for super-easy access! `ln -s path/to/linode-cli.rb ~/bin/linode`

Everything's in one file for ease of use as a script for now, but I plan to bundle it into a gem for proper packaging at some point.
