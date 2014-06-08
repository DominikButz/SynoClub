SynoClub
========

Example iOS application demonstrating how the NSURLSession class can interact with the Synology File Station API.

## Purpose of this iOS application

* This example application has the purpose of showing how to use the Synology File Station API
together with the NSURLSession class and related classes. Regarding networking, it does therefore
not rely on third party dependencies like AFNetworking.
* A major part of this example app has been taken from Ray Wenderlich's NSURLSession-tutorial 
which you can find [here](http://www.raywenderlich.com/51127/nsurlsession-tutorial).
* The major difference is that this example app does not rely on the Dropbox API but
on Synology's File Station API. Instead of storing the note files in the user's dropbox account 
the notes (or "challenges") are uploaded to a shared folder on the user's Disk Station. 
* You can find a guide to the File Station API [here](http://www.synology.com/en-global/support/file_station_API).

## Requirements for running this app with your DS (in the xcode iphone-simulator):
                          
* File Station must be running on your DS  
* The selected shared folder must be accessible by your user with read and write permissions
* In order to use this app outside of your LAN, you must open the necessary ports in your router 
(see DS manual for details - port forwarding) and either resolve your own domain name with your DS or use a DDNS provider (like Synology).
* This application does not support Synology's Quick Connect which is only available for Synology's own mobile apps.
* It is strongly recommended to switch on https for secure server communication. In case you receive an error message with https enabled, 
please log in to your DS with admin permissions and create a self-signed-certificate (control panel / security / certificate).
⋅⋅* Export the certificates and keys. Store the certificates (root and server certificates, both have the file extension .crt) in a secure 
location separately from the key files!
⋅⋅* Simply drag an drop the crt-files into the iphone simulator

## Further development

This app is put under MIT license (see below). **Please feel free to use this app as inspiration or basis
for your own apps. There is a shortage of applications (at least for iOS) that allow users to use 
their own server as backend instead of relying on "big data servers" like Amazon's (Dropbox), Google's, Apple's or even
Facebook's (Parse).**
Synology's DS as easy-to-use home or company server is a great basis for a more secure way of handling confidential data
without renouncing the benefits of mobile applications and cloud computing. 

The app in its current state isn't suitable for uploading it to the app store. Please feel free to modify and extend its
functionality. For example, the app does neither save note files nor photos locally (e.g. in the app's document or temp folder). 
This would make the photo thumbnail table view appear much faster. 


## Dependencies
* FXKeychain created by Nick Lockwood, copyright 2012 Charcoal Design
* DACircularProgress created by Daniel Amitay, copyright 2012 Daniel Amitay.

## License

Copyright (C) 2014 Dominik Butz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation 
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
