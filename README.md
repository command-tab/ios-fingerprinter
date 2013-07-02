ios-fingerprinter
===

A quick little tool to match up provisioning profiles with .p12 files

If you store multiple iOS provisioning profiles and exported certificates (and their private keys) on disk, it can quickly get confusing as to which .p12 belongs with which provisioning profile. You can import them into Xcode and Keychain, but if you're trying to automate a process, those steps are tedious to script. This tool will compare both files and tell you whether the provisioning profile contains a signature of the certificate in the p12, meaning that the two files are related for the purposes of iOS development.

**Requirements**

* a recent-ish version of OS X
* xmlstarlet (perhaps via [Homebrew](http://mxcl.github.io/homebrew/): `brew install xmlstarlet`)

**Usage**

After installing xmlstarlet, running ios-fingerprinter is simple:

```
/path/to/ios-fingerprinter.sh /path/to/prov.mobileprovision /path/to/pkcs.p12 secretp12password
```

You should see output like the following if your provisioning profile contains a certificate matching the one contained in the p12:

![Successful run](https://raw.github.com/commandtab/ios-fingerprinter/master/screenshots/success.png)

Otherwise, you'll see output like this:

![Failure run](https://raw.github.com/commandtab/ios-fingerprinter/master/screenshots/failure.png)
