Note:

The REST API is subject to change by VMWare, therefore *ALWAYS TEST BEFORE RUNNING LIVE*

This is in no way affiliated with VMWare or Workspace ONE.

Use at your own risk.

## About ws-none
List or delete inactive in Workspace One. 

### Running the script
API Credentials
```
  When prompted for credentials - enter username and password of the REST API account.
  The credential provided are saved in the script root.
  This file is encrypted with the *Windows* account of currently logged on user.
  
  If this file is left in the script root, it will be loaded the next time.
  
  Not very useful unless this is to be automated.
 ```

Example output: Action GET
```
**********************
Transcript started, output file is C:\Temp\log\transcript.txt
**********************
serName FirstName LastName  Email
-------- --------- --------  -----
abpe525  abraham   perez
able717  abe       le
abfr955  abner     franklin
able332  abe       lewis
abnu159  abram     nunez
abab724  abner     abenius
abed972  abner     edström

**********************
Windows PowerShell transcript end
End time: ----
**********************
```
