# psduck
A PowerShell script for converting other PowerShell scripts to [USB Rubber Ducky](https://hakshop.myshopify.com/products/usb-rubber-ducky-deluxe?variant=353378649) payloads

## What this does

**Backup your script before running this**

1. Cleans up your PowerShell code using [`Edit-DTWCleanScript`](http://www.dtwconsulting.com/PS/Module_PrettyPrinterV1.htm)
2. Creates a seperate, minified version of your script using [`minJS.psm1`](https://minifyps.codeplex.com/) (which can minify JavaScript and PowerShell)
3. Builds a [Duckyscript](https://github.com/hak5darren/USB-Rubber-Ducky/wiki/Duckyscript) that will quickly and discreetly (as possible) write your minified PowerShell script, save it, execute it, and delete it
4. Uses [`encoder.jar`](https://github.com/hak5darren/USB-Rubber-Ducky/tree/master/Encoder) to encode the Duckyscript to a USB Rubber Ducky payload named `inject.bin`

To use your new payload, simply copy `inject.bin` to a microSD card, and insert the card in the USB Rubber Ducky.

The generated payload is designed to work on Windows 7 or higher. Just plug it in.

## Requirements

- PowerShell 2+
- [Java Runtime](https://java.com/en/download/)

## Licensing

`psduck.ps1` is licensed under the Apache 2.0 license. Everything else in here are dependencies that were written by someone else who didn't include a license :\
I'm using them under Fair Use, considering the authors released these files to the public for free.
