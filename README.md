This is mostly intended to run on my machine but it should be usable outside as I have committed the data too.

To use it, forst you need a file with all the binary packages that needs to be rebuilt, for example:
`urpmf --requires libperl.so.5 | cut -d: -f1 | sort -u > todo.perl`

Then you can call `ruby order.rb todo.perl` which will display something like:
```
== Wave 0: Set of 365 package(s) to rebuild ==
apache-mod_perl
cyrus-imapd
epic5
...

== Wave 1: Set of 72 package(s) to rebuild ==
frozen-bubble
kvirc
perl-Apache-SSLLookup
perl-Attribute-Storage
perl-Authen-DecHpwd
...

== Wave 5: Set of 1 package(s) to rebuild ==
perl-Net-DBus-GLib
```

You can add `-v` to see why each remaining package was not included in each wave.
