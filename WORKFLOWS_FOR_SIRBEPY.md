# Manual tasks for Joe

1. Grant `delete_repo` scope to `gh` CLI so Claude can delete the leftover standalone docs repo:
   ```
   gh auth refresh -h github.com -s delete_repo
   ```
   Then run:
   ```
   gh repo delete SirBepy/a_cxnfusing_framework_docs --yes
   ```
   (The local folder `C:\Users\tecno\Desktop\Projects\a_cxnfusing_framework_docs` will be removed by Claude once scope is granted. If you'd rather nuke it yourself, just `rm -rf` it.)
