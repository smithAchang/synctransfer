# synctransfer

Based On CentOS7 provoding ftp service and rsync service to build synchronisation between outer area and inner area, which are isloated by different dirs to keep safety.

 +-------------+                                   +--------------+
 | ftp         |    rsync dir synchronising        |  ftp         |
 | outter      |   --------------------------->    |  inner       |
 | area        |                                   |  area        |
 +-------------+                                   |              |
                                                   |  *sharing*   |
                                                   |  *with*      |
                       pull                        |  *ftp*       |
 ftp super user    <---------------------------    |  *superuser* |
                                                   +--------------+

# functions
+ ftpout user can only put files needing transfered to inner area
+ ftpin  user can get ftpout user sharing files through synchronisation
++ ftpin user can put files wanted to be pulled by ftpsuper user at outter area. e.g these files may has risk for information security
+ ftp super user can  pull files providing by ftpin user; once the file is pulled, the file cannot be deleted by any ftp user keeped for audit
++ if you has smtp network infrastructure,you can set up sending mail trigged by ftp superuser puling operation


# deployment
+ you can use deploy.sh to set up basic functions
+ you can use scripts/autosendmail/deploy.sh to set up sending mail service trigged by ftp superuser puling operation
