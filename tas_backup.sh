#!/bin/bash
########################################################################
# TIbero Backup Script Sample 
#  - Backup Store Type: FileSystem or TAS
#  - Backup Method: BEGIN/END or tbrmgr
#
# Sciprt Version History
#   - Version 2024.10.11, by junsu
#
########################################################################

####################################################
# Sciprt Parameter Check
####################################################
# User Settings.
#-----------------------------------------------------------------------
# Backup Store Type (Y or N)
BACKUP_FILESYSTEM=Y
BACKUP_TAS=N 

# Backup Method (Y or N)
BACKUP_BEGINEND=Y
BACKUP_TBRMGR=N

# Backup Directory
WORK_DIR=/root/work/backup
ARCH_DIR=/root/work/backup

# Backup Archive Include
BACKUP_ARCHIVE_INCLUDE=Y

# Backup Tibero OS User
TB_USER=root
TB_HOME=/root/tibero7

# Backup Tibero DB User and Password
DB_USER=sys
DB_PASS=tibero

# Backup Store Type: TAS, Connection TAS Port
TAS_PORT=

# Backup Method: BACKUP_BEGINEND
# Y: Prev Active Ignore , N: Prev Active Stop
BACKUP_BEGINEND_STATE_IGRNORE=N

# Backup Method: BACKUP_TBRMGR, Options (Y or N)
TBRMGR_INCREMENTAL_BACKUP=N
TBRMGR_COMPRESS=N
TBRMGR_WITH_ARCHIVELOG=N
TBRMGR_WITH_PASSWORD_FILE=N 
#-----------------------------------------------------------------------

# Do Not Change
#-----------------------------------------------------------------------
SCRIPT_NAME=${0}
BACKUP_TIME=`date +%y%m%d_%H%M`
BACKUP_DIR="${WORK_DIR}"/"${BACKUP_TIME}"
BACKUP_CTL="${BACKUP_DIR}"/control.ctl.bak
BACKUP_CONFIG="${BACKUP_DIR}"/tibero_config.bak
META_FILE="${BACKUP_DIR}"/meta/datafile.log
META_TABLESPACE="${BACKUP_DIR}"/meta/tablespace.log
LOG_SCIPRT="${BACKUP_DIR}"/log/tibero_backup.log
LOG_BACKUP_STATUS_PREV="${BACKUP_DIR}"/log/tibero_backup_status_prev.log
LOG_BACKUP_STATUS_POST="${BACKUP_DIR}"/log/tibero_backup_status_post.log
su - ${TB_USER} -c "mkdir -p "${BACKUP_DIR}"/arch"
su - ${TB_USER} -c "mkdir -p "${BACKUP_DIR}"/meta"
su - ${TB_USER} -c "mkdir -p "${BACKUP_DIR}"/log"
LINE_HEAD="#################################################################################"
LINE_MODULE="---------------------------------------------------------------------------------"
#-----------------------------------------------------------------------

####################################################
# Sciprt Error Check
####################################################
function_error(){
ERROR_FLAG=N
echo "## Error Check Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"

# Script Paramter Checking
#-----------------------------------------------------------------------
if [ -z "${TB_USER}" ] || [ -z "${TB_HOME}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - TB_USER or TB_HOME Checking."
    echo "   - TB_USER: ${TB_USER}"
    echo "   - TB_HOME: ${TB_HOME}"
else
    echo "  SUCCESS - TB_USER or TB_HOME Checking."
    echo "   - TB_USER: ${TB_USER}"
    echo "   - TB_HOME: ${TB_HOME}"
fi

if [ -z "$ARCH_DIR" ] || [ -z "${WORK_DIR}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - BACKUP_DIR or WORK_DIR or ARCH_DIR Checking."
    echo "   - BACKUP_DIR: ${BACKUP_DIR}"
    echo "   - WORK_DIR  : ${WORK_DIR}"
    echo "   - ARCH_DIR  : ${ARCH_DIR}"
else
    echo "  SUCCESS - BACKUP_DIR or WORK_DIR or ARCH_DIR Checking."
    echo "   - BACKUP_DIR: ${BACKUP_DIR}"
    echo "   - WORK_DIR  : ${WORK_DIR}"
    echo "   - ARCH_DIR  : ${ARCH_DIR}"
fi

if [ -z "${DB_USER}" ] || [ -z "${DB_PASS}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - DB_USER or DB_PASS Checking."
    echo "   - DB_USER: ${DB_USER}"
    echo "   - DB_PASS: ${DB_PASS}"
else
    echo "  SUCCESS - DB_USER or DB_PASS Checking."
    echo "   - DB_USER: ${DB_USER}"
    echo "   - DB_PASS: ******"
fi

if [ "Y" == "${BACKUP_FILESYSTEM}" ] && [ "Y" == "${BACKUP_TAS}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - BACKUP_FILESYSTEM or BACKUP_TAS Checking."
    echo "   - BACKUP_FILESYSTEM: ${BACKUP_FILESYSTEM}"
    echo "   - BACKUP_TAS: ${BACKUP_TAS}"
else
    echo "  SUCCESS - BACKUP_FILESYSTEM or BACKUP_TAS Checking."
    echo "   - BACKUP_FILESYSTEM: ${BACKUP_FILESYSTEM}"
    echo "   - BACKUP_TAS: ${BACKUP_TAS}"
fi

if [ "N" == "${BACKUP_BEGINEND}" ] && [ "Y" == "${BACKUP_TBRMGR}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - BACKUP_BEGINEND or BACKUP_TBRMGR Checking."
    echo "   - BACKUP_BEGINEND: ${BACKUP_BEGINEND}"
    echo "   - BACKUP_TBRMGR: ${BACKUP_TBRMGR}"
else
    echo "  SUCCESS - BACKUP_BEGINEND or BACKUP_TBRMGR Checking."
    echo "   - BACKUP_BEGINEND: ${BACKUP_BEGINEND}"
    echo "   - BACKUP_TBRMGR: ${BACKUP_TBRMGR}"
fi
#-----------------------------------------------------------------------

# Directory Checking
#-----------------------------------------------------------------------
if [ ! -d "${BACKUP_DIR}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - BACKUP_DIR Directory Checking"
    echo "    - Not Access."
else
    echo "  SUCCESS - BACKUP_DIR Directory Checking"
    echo "    - Access."
fi

if [ ! -d "${BACKUP_DIR}"/meta ]
then
    ERROR_FLAG=Y
    echo "  ERROR - \$BACKUP_DIR/meta Directory Checking"
    echo "    - Not Access."

else
    echo "  SUCCESS - \$BACKUP_DIR/meta Directory Checking"
    echo "    - Access."
fi 


if [ ! -d "${BACKUP_DIR}"/log ]
then
    ERROR_FLAG=Y
    echo "  ERROR - \$BACKUP_DIR/log Directory Checking"
    echo "    - Not Access."

else
    echo "  SUCCESS - \$BACKUP_DIR/log Directory Checking"
    echo "    - Access."
fi 

if [ ! -d "${WORK_DIR}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - WORK_DIR Directory Checking."
    echo "    - Not Access."
else
    echo "  SUCCESS - WORK_DIR Directory Checking."
    echo "    - Access."
fi


if [ ! -d "${ARCH_DIR}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - ARCH_DIR Directory Checking."
    echo "    - Not Access."
else
    echo "  SUCCESS - ARCH_DIR Directory Checking."
    echo "    - Access."
fi 
#-----------------------------------------------------------------------

# Running Database
#-----------------------------------------------------------------------
TB_PROC_CHK=`ps -ef |grep -v grep |grep -w "${TB_USER}"  |grep "tblistener" |awk '{print $2}'`
if [ -z "${TB_USER}" ] || [ -z "${TB_HOME}" ]
then
    ERROR_FLAG=Y
elif [ -z "${TB_PROC_CHK}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - Tibero Process Checking."
    echo "    - Process Not Running"
    
else
    echo "  SUCCESS - Tibero Process Checking."
    echo "    - Process Running"
    ps -ef |grep -v grep |grep -w "${TB_USER}"  |grep -E "tblistener|tbsvr"|awk '{print "     - "$0}'
fi


# TAS 접속 테스트 추가 할것
TB_CONN_CHK=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select 'CONN' from dual;
EOF
"`
if [ -z "${DB_USER}" ] || [ -z "${DB_PASS}" ]
then
    ERROR_FLAG=Y
elif [ "CONN" != "${TB_CONN_CHK}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - Tibero Connection Checking."
    echo "    - Not Connected"
elif [ "CONN" = "${TB_CONN_CHK}" ]
then
    echo "  SUCCESS - Tibero Connection Checking."
    echo "    - Connected"
fi

TB_BACKUP_CHK=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select 'ACTIVE' from _vt_backup where status = 1 and rownum = 1;
EOF
"`

if [ "ACTIVE" == "${TB_BACKUP_CHK}" ] && [ "N" == "${BACKUP_BEGINEND_STATE_IGRNORE}" ]
then
    ERROR_FLAG=Y
    echo "  ERROR - Tibero Backup Checking."
    echo "    - Backup Active State."
elif [ "ACTIVE" == "${TB_BACKUP_CHK}" ] && [ "Y" == "${BACKUP_BEGINEND_STATE_IGRNORE}" ]
then
    echo "  SUCCESS - Tibero Backup Checking."
    echo "    - Backup Active State."
    echo "    - Backup Active IGNORE."
else 
    echo "  SUCCESS - Tibero Backup Checking."
    echo "    - Backup Not Active State."
fi
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Error Check End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"

# Error Y Exit
#-----------------------------------------------------------------------
if [ "Y" == "${ERROR_FLAG}" ]
then
    exit 0
fi
#-----------------------------------------------------------------------
}

####################################################
# Script Meta Generation
####################################################
function_meta_getting(){
echo "## Backup Meta Getting Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
echo "  - \$BACKUP_DIR=${BACKUP_DIR}"
echo "  - \${BACKUP_DIR}         # Backup Directory"
echo "  - \${BACKUP_DIR}/meta    # Backup meta Path"
echo "  - \${BACKUP_DIR}/log     # Backup Log Path"

# TableSpace Name Meta File
#-----------------------------------------------------------------------
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set linesize 9999
set feedback off
select tablespace_name from dba_tablespaces where contents != 'TEMPORARY';
EOF
" |grep -v "SQL>" > ${META_TABLESPACE}
#-----------------------------------------------------------------------

# TableSpace Datafile Meta File
#-----------------------------------------------------------------------
echo "  - Datafile Name Checking"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set linesize 9999
set feedback off
select file_name from dba_datafiles where tablespace_name in (select tablespace_name from dba_tablespaces where contents != 'TEMPORARY');
EOF
" |grep -v "SQL>" > ${META_FILE}
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Backup Meta Getting End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}

####################################################
# 
####################################################
function_script_options(){
# Sciprt Parameter
#-----------------------------------------------------------------------
su - ${TB_USER} -c "echo"
echo "${LINE_MODULE}"
echo "## tibero_backup.sh Sciprt Parameters"
echo "${LINE_MODULE}"
#-----------------------------------------------------------------------
echo "   - BACKUP_FILESYSTEM: ${BACKUP_FILESYSTEM}"
echo "   - BACKUP_TAS: ${BACKUP_TAS}"
echo "      - TAS_PORT: ${TAS_PORT}"
#-----------------------------------------------------------------------
echo "   - BACKUP_BEGINEND: ${BACKUP_BEGINEND}"
echo "      - BACKUP_BEGINEND_STATE_IGRNORE: ${BACKUP_BEGINEND_STATE_IGRNORE}"
echo "   - BACKUP_TBRMGR: ${BACKUP_TBRMGR}"
#-----------------------------------------------------------------------
echo "   - WORK_DIR: ${WORK_DIR}"
echo "   - ARCH_DIR: ${ARCH_DIR}"
#-----------------------------------------------------------------------
echo "   - TB_USER: ${TB_USER}"
echo "   - TB_HOME: ${TB_HOME}"
echo "   - DB_USER: ${DB_USER}"
echo "   - DB_PASS: ${DB_PASS}"
#-----------------------------------------------------------------------
echo "   - TBRMGR_INCREMENTAL_BACKUP: ${TBRMGR_INCREMENTAL_BACKUP}"
echo "   - TBRMGR_COMPRESS: ${TBRMGR_COMPRESS}"
echo "   - TBRMGR_WITH_ARCHIVELOG: ${TBRMGR_WITH_ARCHIVELOG}"
echo "   - TBRMGR_WITH_PASSWORD_FILE: ${TBRMGR_WITH_PASSWORD_FILE}"
#-----------------------------------------------------------------------
echo "   - BACKUP_TIME: ${BACKUP_TIME}"
echo "   - BACKUP_DIR: ${BACKUP_DIR}"
echo "   - BACKUP_CTL: ${BACKUP_CTL}"
echo "   - BACKUP_CONFIG: ${BACKUP_CONFIG}"
#-----------------------------------------------------------------------
echo "   - META_FILE: ${META_FILE}"
echo "   - META_TABLESPACE: ${META_TABLESPACE}"
#-----------------------------------------------------------------------
echo "   - LNAG: ${LANG}"
echo "   - LOG_SCIPRT: ${LOG_SCIPRT}"
echo "   - LOG_BACKUP_STATUS_PREV: ${LOG_BACKUP_STATUS_PREV}"
echo "   - LOG_BACKUP_STATUS_POST: ${LOG_BACKUP_STATUS_POST}"
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
#grep -A100 "Sciprt Parameter Check" ${SCRIPT_NAME} |grep -B100 "Sciprt Error Check" |grep -vE "#|^$"
}
funciton_backup_configuration(){
echo "${LINE_HEAD}"
echo "# Tibero Configuration Backup"
echo "${LINE_HEAD}"
# Tibero Configuration
#-----------------------------------------------------------------------
su - ${TB_USER} <<EOF
echo "${LINE_MODULE}"
echo "## Tibero Version"
echo "${LINE_MODULE}"
tbboot -v
echo
echo "${LINE_MODULE}"
echo "## Tibero License"
echo "${LINE_MODULE}"
tbboot -l
echo
cat $TB_HOME/license/license.xml
echo
echo "${LINE_MODULE}"
echo "## TB_SID: ${TB_SID}.tip"
echo "${LINE_MODULE}"
if [ -z "${TB_SID}" ]
then
    echo "  SKIP - TB_SID empty."
else
    cat ${TB_HOME}/config/${TB_SID}.tip
fi
echo
echo "${LINE_MODULE}"
echo "## CM_SID: ${CM_SID}.tip"
echo "${LINE_MODULE}"
if [ -z "${CM_SID}" ]
then 
    echo "  SKIP - CM_SID empty."
else
    cat ${TB_HOME}/config/${CM_SID}.tip
fi
echo
echo "${LINE_MODULE}"
echo "## tbdsn.tbr"
echo "${LINE_MODULE}"
if [ -z "${TB_HOME}" ]
then
    echo "  SKIP - TB_HOME empty."
else
    cat $TB_HOME/client/config/tbdsn.tbr
fi
echo
echo "${LINE_MODULE}"
echo "## CM Resource"
echo "${LINE_MODULE}"
if [ -z "${CM_SID}" ]
then 
    echo "  SKIP - CM_SID empty."
else
    cmrctl show all
fi
echo
echo "${LINE_MODULE}"
echo "## Tibero User Profile"
echo "${LINE_MODULE}"
if [ -z "${TB_HOME}" ]
then
    echo "  SKIP - TB_HOME empty."
else
    cat $HOME/.bash_profile
fi
echo
echo "${LINE_MODULE}"
echo "## Java Version"
echo "${LINE_MODULE}"
java -version 2>&1
echo
echo "${LINE_MODULE}"
echo "## Tibero User Process"
echo "${LINE_MODULE}"
if [ -z "${TB_USER}" ]
then
    echo "  SKIP - TB_USER empty."
else
    ps -ef |grep -w "${TB_USER}"
fi
echo
EOF
#-----------------------------------------------------------------------

# Tibero dba_libraries
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## dba_libraries"
echo "${LINE_MODULE}"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
select * from dba_libraries;
EOF
"

# Tibero File List
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero File List"
echo "${LINE_MODULE}"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set feedback off
set linesize 132
col \"Control Files\" format a87
SELECT name  \"Control Files\" FROM v\\\$controlfile;

set feedback off
set linesize 100
col \"Group#\" format 9999999
col \"Member\" format a60
col \"Type\"   format a8
col \"Size(MB)\" format 9,999,999
SELECT 
    vl.group# \"Group#\", 
    vlf.member \"Member\", 
    vlf.type \"Type\" , 
    vl.bytes/1024/1024 as \"Size(MB)\"
FROM v\\\$log vl, v\\\$logfile vlf
WHERE vl.group# = vlf.group#;
set feedback off
set linesize 120
set pagesize 100
col \"Tablespace Name\" format a20
col \"File Name\" format a60
col \"Size(MB)\" format 999,999,999
col \"MaxSize(MB)\" format 999,999,999
SELECT *
FROM (
	SELECT tablespace_name as \"Tablespace Name\",
	           file_name as \"File Name\",
	           bytes/1024/1024 as \"Size(MB)\",
	           maxbytes/1024/1024 as \"MaxSize(MB)\"
	FROM dba_data_files
	UNION ALL
	SELECT tablespace_name as \"Tablespace Name\",
	       file_name as \"File Name\" ,
	       bytes/1024/1024 \"Size(MB)\",
	       maxbytes/1024/1024 \"MaxSize(MB)\"
	FROM dba_temp_files
)
ORDER BY 1,2;
EOF
"
echo
#-----------------------------------------------------------------------

# Tibero File Usage
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero File Usage"
echo "${LINE_MODULE}"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set feedback off
set linesize 150
set pagesize 100
col \"Tablespace Name\" format a20
col \"Bytes(MB)\"       format 999,999,999
col \"Used(MB)\"        format 999,999,999
col \"Percent(%)\"      format 9999999.99
col \"Free(MB)\"        format 999,999,999
col \"Free(%)\"         format 9999.99
col \"MaxBytes(MB)\"    format 999,999,999
col \"MAX_Free(%)\"     format 9999999.99
SELECT ddf.tablespace_name \"Tablespace Name\",
       ddf.bytes/1024/1024 \"Bytes(MB)\",
       (ddf.bytes - dfs.bytes)/1024/1024 \"Used(MB)\",
       round(((ddf.bytes - dfs.bytes) / ddf.bytes) * 100, 2) \"Percent(%)\",
       dfs.bytes/1024/1024 \"Free(MB)\",
       ROUND((1 - ((ddf.bytes - dfs.bytes) / ddf.bytes)) * 100, 2) \"Free(%)\",
       ROUND(ddf.MAXBYTES/1024/1024,2) \"MaxBytes(MB)\",
       ROUND((1 - ((ddf.bytes-dfs.bytes)/ddf.maxbytes))*100,2) \"MAX_Free(%)\"
FROM
   (SELECT tablespace_name, sum(bytes) bytes, sum(decode(maxbytes,0,bytes,maxbytes)) maxbytes
   FROM dba_data_files
   GROUP BY tablespace_name) ddf,
   (SELECT tablespace_name, sum(bytes) bytes
   FROM   dba_free_space
   GROUP BY tablespace_name) dfs
WHERE ddf.tablespace_name = dfs.tablespace_name
ORDER BY ((ddf.bytes-dfs.bytes)/ddf.bytes) DESC;

set linesize 130
set feedback off
col \"Tablespace Name\" format a20
col \"Size(MB)\" format 999,9999,999.99
col \"MaxSize(MB)\" format 999,9999,999.99
SELECT tablespace_name \"Tablespace Name\",
       SUM(bytes)/1024/1024 \"Size(MB)\",
       SUM(maxbytes)/1024/1024 \"MaxSize(MB)\"
FROM dba_temp_files
GROUP BY tablespace_name
ORDER BY 1;
EOF
"
echo
#-----------------------------------------------------------------------
}

function_collection_backup_status_prev(){
echo "${LINE_HEAD}"
echo "# Collection Log Prev Backup Status"
echo "${LINE_HEAD}"

# Tibero Archive History
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero Archive"
echo "${LINE_MODULE}"

ARC_PREV_NUMBER=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select to_number(max(sequence#)) from _VT_ARCHIVED_LOG
where thread#=(select instance_number from _VT_INSTANCE);
EOF
"`

su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 5000
set feedback off
select * from v\\\$archived_log where sequence# >= ${ARC_PREV_NUMBER} order by sequence#;
EOF
"
#-----------------------------------------------------------------------


# Tibero Backup Status (BEGIN/END)
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero Backup Status (BEGIN/END)"
echo "${LINE_MODULE}"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 5000
set linesize 300
set feedback off
select file#, status, change#, to_char(time,'YYYY/MM/DD hh24:mi:ss') backup_time from v\\\$backup;
EOF
"
#-----------------------------------------------------------------------

# Tibero Backup Status (tbrmgr)
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero Backup Status (tbrmgr)"
echo "${LINE_MODULE}"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 5000
set linesize 300
set feedback off
SELECT * FROM sys.rmgr_backup_list WHERE set_id >= (SELECT max(set_id) - 1 FROM sys.rmgr_backup_list);
EOF
"
#-----------------------------------------------------------------------
}

function_collection_backup_status_post(){
echo "${LINE_HEAD}"
echo "# Collection Log Post Backup Status"
echo "${LINE_HEAD}"

# Tibero Archive History
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero Archive"
echo "${LINE_MODULE}"

ARC_POPST_NUMBER=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select to_number(max(sequence#)) from _VT_ARCHIVED_LOG
where thread#=(select instance_number from _VT_INSTANCE);
EOF
"`

su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 5000
set feedback off
select * from v\\\$archived_log where sequence# BETWEEN ${ARC_PREV_NUMBER} AND ${ARC_END_NUMBER} order by sequence#;
EOF
"
#-----------------------------------------------------------------------


# Tibero Backup Status (BEGIN/END)
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero Backup Status (BEGIN/END)"
echo "${LINE_MODULE}"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 5000
set linesize 300
set feedback off
select file#, status, change#, to_char(time,'YYYY/MM/DD hh24:mi:ss') backup_time from v\\\$backup;
EOF
"
#-----------------------------------------------------------------------

# Tibero Backup Status (tbrmgr)
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Tibero Backup Status (tbrmgr)"
echo "${LINE_MODULE}"
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 5000
set linesize 300
set feedback off
SELECT * FROM sys.rmgr_backup_list WHERE set_id >= (SELECT max(set_id) - 1 FROM sys.rmgr_backup_list);
EOF
"
#-----------------------------------------------------------------------
}

####################################################
# Controlfile Generation
####################################################
function_controlfile_backup(){
echo "## Controlfile Backup Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
echo "  - Controfile Path: ${BACKUP_CTL}"

# Controfile File 
#-----------------------------------------------------------------------
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
alter database backup controlfile to trace as '$BACKUP_CTL' reuse noresetlogs;
EOF
"
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## Controlfile Backup End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}


####################################################
# BEGIN BACKUP
####################################################
function_begin_backup(){
echo "## Tablespace Begin Backup Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
echo "  - Tablespace Name : `echo ${META_TABLESPACE[@]}`"
tbs_name_var=`cat ${META_TABLESPACE}`
for tbs_name in ${tbs_name_var[@]}
do
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
alter tablespace ${tbs_name} begin backup wait;
EOF
"
done
echo "${LINE_MODULE}"
echo "## Tablespace Begin Backup End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}

####################################################
# File System Datafile Copy
####################################################
function_tablespace_filecopy_filesystem(){
if [ "Y" == "${BACKUP_FILESYSTEM}" ] && [ "N" == "${BACKUP_TAS}" ]
then
echo "## Tablespace FileCopy (FileSystem) Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
DATAFILE_LIST=`cat ${META_FILE}`
for DATAFILE_NAME in ${DATAFILE_LIST[@]}
do
    echo "  - Datafile Copy: ${file_name}"
    cp ${DATAFILE_NAME} ${BACKUP_DIR}
done

BACKUP_DIR_META=`ls ${BACKUP_DIR}`
echo "  - File Copy List"
echo ${BACKUP_DIR_META[@]}
echo "${LINE_MODULE}"
echo "## Tablespace FileCopy (FileSystem) End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
fi
}

####################################################
# TAS Datafile Copy
####################################################
function_tablespace_filecopy_tas(){
if [ "N" == "${BACKUP_FILESYSTEM}" ] && [ "Y" == "${BACKUP_TAS}" ]
then
echo "## Tablespace FileCopy (TAS) Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
DATAFILE_LIST=`cat ${META_FILE}`
for DATAFILE_NAME in ${DATAFILE_LIST[@]}
do
tbascmd ${TAS_PORT} <<EOF
cptolocal ${DATAFILE_NAME} ${BACKUP_DIR}
EOF
done

BACKUP_DIR_META=`echo `ls ${BACKUP_DIR}``
echo "  - File Copy List"
echo ${BACKUP_DIR_META[@]}
echo "${LINE_MODULE}"
echo "## Tablespace FileCopy (TAS) End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
fi
}

####################################################
# END BACKUP
####################################################
function_end_backup(){
echo "## Tablespace End Backup Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
tbs_name_var=`cat ${META_TABLESPACE}`
for tbs_name in ${tbs_name_var[@]}
do
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
alter tablespace ${tbs_name} end backup wait;
EOF
" 
done
echo "${LINE_MODULE}"
echo "## Tablespace End Backup End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}

####################################################
# Archive Log Begin/End
####################################################
function_archive_begin(){
echo "## Archive Begin Sequence Number Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
ARC_BEGIN_NUMBER=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select to_number(max(sequence#)) from _VT_ARCHIVED_LOG
where thread#=(select instance_number from _VT_INSTANCE);
EOF
"`
echo "  - Archive Log Begin Sequence Nuumber : ${ARC_BEGIN_NUMBER}"
echo "${LINE_MODULE}"
echo "## Archive Begin Sequence Number End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}

function_archive_end(){
echo "## Archive End Sequence Number Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
ARC_END_NUMBER=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select to_number(max(sequence#)) from _VT_ARCHIVED_LOG
where thread#=(select instance_number from _VT_INSTANCE);
EOF
"`
echo "  - Archive Log Begin Sequence Nuumber : ${ARC_END_NUMBER}"
echo "${LINE_MODULE}"
echo "## Archive End Sequence Number End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}

function_archive_copy(){
echo "## Archive Log Copy Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
ARC_BEGIN_END_LIST=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select name from _VT_ARCHIVED_LOG where sequence# >= ${ARC_BEGIN_NUMBER};
EOF"`

for ARC_NAME in ${ARC_BEGIN_END_LIST[@]}
do
    echo "  - Archive Log Copy: ${ARC_NAME}"
    cp -rp ${ARC_NAME} ${BACKUP_DIR}/arch
done
echo "${LINE_MODULE}"
echo "## Archive Log Copy End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}


####################################################
# Log Switch
####################################################
function_log_switch(){
echo "## Log Switch Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
LOG_SWITCH_CYCLE_NUMBER=1
LOG_SWITCH_COUNT=`su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
set pagesize 0
set feedback off
select max(group#) + 2 from _vt_log;
EOF
"`
while [ ${LOG_SWITCH_CYCLE_NUMBER} -le ${LOG_SWITCH_COUNT} ]
do
su - ${TB_USER} -c "
tbsql ${DB_USER}/${DB_PASS} -s <<EOF
alter system switch logfile;
EOF
"
LOG_SWITCH_CYCLE_NUMBER=$((LOG_SWITCH_CYCLE_NUMBER + 1))
done

echo "${LINE_MODULE}"
echo "## Log Switch End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}

####################################################
# tbrmgr
####################################################
function_tbrmgr(){
# tbrmgr options setting
#-----------------------------------------------------------------------
TBRMGR_OPTIONS=""
if [ "Y" == "${TBRMGR_COMPRESS}" ]
then
    TBRMGR_OPTIONS="${TBRMGR_OPTIONS} -c"
fi

if [ "Y" == "${TBRMGR_WITH_PASSWORD_FILE}" ]
then
    TBRMGR_OPTIONS="${TBRMGR_OPTIONS} --with-password-file"
fi

if [ "Y" == "${TBRMGR_WITH_ARCHIVELOG}" ]
then
    TBRMGR_OPTIONS="${TBRMGR_OPTIONS} --with-archivelog"
fi
#-----------------------------------------------------------------------

echo "## TBRMGR Backup Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
echo "  - TBRMGR Backup Options: ${TBRMGR_OPTIONS}"
# tbrmgr running
#-----------------------------------------------------------------------
su - ${TB_USER} -c "
tbrmgr backup -s -v -L ${BACKUP_DIR}/log -o ${BACKUP_DIR} ${TBRMGR_OPTIONS}
"
# 100% Gathering: |strings  |grep -vw "[0-9][0-9].[0-9]%" |grep -vw "[0-9].[0-9]%"
#-----------------------------------------------------------------------
echo "${LINE_MODULE}"
echo "## TBRMGR Backup End: `date +%Y-%m-%d\ %T`"
echo "${LINE_MODULE}"
}

####################################################
# Script Start Message
####################################################
function_script_start(){
echo "${LINE_HEAD}"
echo "# tibero_backup.sh Script Start: `date +%Y-%m-%d\ %T`"
echo "${LINE_HEAD}"
}

####################################################
# Script End Message
####################################################
functipn_script_end(){
echo "${LINE_HEAD}"
echo "# tibero_backup.sh Script End: `date +%Y-%m-%d\ %T`"
echo "${LINE_HEAD}"
}

####################################################
# Main
####################################################
function_main(){  
    function_backup_database(){
        # begin/end backup
        if [ "N" == "${BACKUP_TBRMGR}" ]
        then
            function_script_start
            function_script_options
            function_error
            function_meta_getting
            function_controlfile_backup
            function_archive_begin
            function_begin_backup
            function_tablespace_filecopy_filesystem
            function_tablespace_filecopy_tas
            function_end_backup
            function_log_switch
            function_archive_end
            function_archive_copy            
            functipn_script_end         
        # tbrmgr backup
        elif [ "Y" == "${BACKUP_TBRMGR}"  ]
        then
            function_script_start
            function_script_options
            function_error
            function_meta_getting
            function_controlfile_backup
            function_tbrmgr
            functipn_script_end
        fi
    }
    function_collection_backup_status_prev 1>>${LOG_BACKUP_STATUS_PREV} 2>/dev/null
    funciton_backup_configuration 1>>${BACKUP_CONFIG} 2>/dev/null
    function_backup_database 1>>${LOG_SCIPRT} 2>/dev/null
    function_collection_backup_status_post 1>>${LOG_BACKUP_STATUS_POST} 2>/dev/null
}

####################################################
# Script Call
####################################################

function_main

########################################################################