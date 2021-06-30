# mtmp2json
Scripts to convert between \*.mtmp, \*.etmp files and JSON (JavaScript Object Notation) data.

## Why is this useful?
You could use this code to:
* Examine and edit your profile files without using PCS's software, e.g. on your own computer
* Create your profile files using a script instead of having to do it manually
* Reuse your MTM profile files on the ETM, and vice versa

## Why JSON?
JSON is both human-readable (you can open it in Notepad) and machine-readable. An example JSON file is provided (with comments, which break the rules of JSON so this can't be parsed) to explain the JSON tags corresponding to each setting. An identical JSON file is provided without the comments so you can try it out.

### Notes
1. The scripts are written in MATLAB, and will work if you just open them in MATLAB and press Run. They can also be used as functions in your own script to create more complex profile files, e.g. long scuffing profiles.
2. There are differences between the MTM and the ETM - check these before converting files. The main ones are:
  * The machines are capable of different loads and speeds - make sure it can do what you're asking it to! These scripts won't check your inputs like the profile editor does.
  * The ETM has no ECR so if your JSON contains ECRoption settings these will be ignored when using json2mtmp to save a \*.etmp file
  * The ETM does not have Bidirectional Traction and Bidirectional Stribeck steps
3. If anything goes wrong, let me know! dam216@ic.ac.uk
