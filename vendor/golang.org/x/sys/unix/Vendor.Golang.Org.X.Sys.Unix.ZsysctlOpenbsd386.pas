{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZsysctlOpenbsd386;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesOpenbsd386;

type
	Tmibentry = record
		mCtlname : string;
		mCtloid : TArray<_C_int>;
	end;

var
	sysctlMib : TArray<Tmibentry>;

implementation

initialization
	SetLength( sysctlMib, 145 );
	sysctlMib[0].mCtlname := 'ddb.console'; sysctlMib[0].mCtloid := TArray<_C_int>.Create( 9, 6 );
	sysctlMib[1].mCtlname := 'ddb.log'; sysctlMib[1].mCtloid := TArray<_C_int>.Create( 9, 7 );
	sysctlMib[2].mCtlname := 'ddb.max_line'; sysctlMib[2].mCtloid := TArray<_C_int>.Create( 9, 3 );
	sysctlMib[3].mCtlname := 'ddb.max_width'; sysctlMib[3].mCtloid := TArray<_C_int>.Create( 9, 2 );
	sysctlMib[4].mCtlname := 'ddb.panic'; sysctlMib[4].mCtloid := TArray<_C_int>.Create( 9, 5 );
	sysctlMib[5].mCtlname := 'ddb.radix'; sysctlMib[5].mCtloid := TArray<_C_int>.Create( 9, 1 );
	sysctlMib[6].mCtlname := 'ddb.tab_stop_width'; sysctlMib[6].mCtloid := TArray<_C_int>.Create( 9, 4 );
	sysctlMib[7].mCtlname := 'ddb.trigger'; sysctlMib[7].mCtloid := TArray<_C_int>.Create( 9, 8 );
	sysctlMib[8].mCtlname := 'fs.posix.setuid'; sysctlMib[8].mCtloid := TArray<_C_int>.Create( 3, 1, 1 );
	sysctlMib[9].mCtlname := 'hw.allowpowerdown'; sysctlMib[9].mCtloid := TArray<_C_int>.Create( 6, 22 );
	sysctlMib[10].mCtlname := 'hw.byteorder'; sysctlMib[10].mCtloid := TArray<_C_int>.Create( 6, 4 );
	sysctlMib[11].mCtlname := 'hw.cpuspeed'; sysctlMib[11].mCtloid := TArray<_C_int>.Create( 6, 12 );
	sysctlMib[12].mCtlname := 'hw.diskcount'; sysctlMib[12].mCtloid := TArray<_C_int>.Create( 6, 10 );
	sysctlMib[13].mCtlname := 'hw.disknames'; sysctlMib[13].mCtloid := TArray<_C_int>.Create( 6, 8 );
	sysctlMib[14].mCtlname := 'hw.diskstats'; sysctlMib[14].mCtloid := TArray<_C_int>.Create( 6, 9 );
	sysctlMib[15].mCtlname := 'hw.machine'; sysctlMib[15].mCtloid := TArray<_C_int>.Create( 6, 1 );
	sysctlMib[16].mCtlname := 'hw.model'; sysctlMib[16].mCtloid := TArray<_C_int>.Create( 6, 2 );
	sysctlMib[17].mCtlname := 'hw.ncpu'; sysctlMib[17].mCtloid := TArray<_C_int>.Create( 6, 3 );
	sysctlMib[18].mCtlname := 'hw.ncpufound'; sysctlMib[18].mCtloid := TArray<_C_int>.Create( 6, 21 );
	sysctlMib[19].mCtlname := 'hw.ncpuonline'; sysctlMib[19].mCtloid := TArray<_C_int>.Create( 6, 25 );
	sysctlMib[20].mCtlname := 'hw.pagesize'; sysctlMib[20].mCtloid := TArray<_C_int>.Create( 6, 7 );
	sysctlMib[21].mCtlname := 'hw.physmem'; sysctlMib[21].mCtloid := TArray<_C_int>.Create( 6, 19 );
	sysctlMib[22].mCtlname := 'hw.product'; sysctlMib[22].mCtloid := TArray<_C_int>.Create( 6, 15 );
	sysctlMib[23].mCtlname := 'hw.serialno'; sysctlMib[23].mCtloid := TArray<_C_int>.Create( 6, 17 );
	sysctlMib[24].mCtlname := 'hw.setperf'; sysctlMib[24].mCtloid := TArray<_C_int>.Create( 6, 13 );
	sysctlMib[25].mCtlname := 'hw.usermem'; sysctlMib[25].mCtloid := TArray<_C_int>.Create( 6, 20 );
	sysctlMib[26].mCtlname := 'hw.uuid'; sysctlMib[26].mCtloid := TArray<_C_int>.Create( 6, 18 );
	sysctlMib[27].mCtlname := 'hw.vendor'; sysctlMib[27].mCtloid := TArray<_C_int>.Create( 6, 14 );
	sysctlMib[28].mCtlname := 'hw.version'; sysctlMib[28].mCtloid := TArray<_C_int>.Create( 6, 16 );
	sysctlMib[29].mCtlname := 'kern.arandom'; sysctlMib[29].mCtloid := TArray<_C_int>.Create( 1, 37 );
	sysctlMib[30].mCtlname := 'kern.argmax'; sysctlMib[30].mCtloid := TArray<_C_int>.Create( 1, 8 );
	sysctlMib[31].mCtlname := 'kern.boottime'; sysctlMib[31].mCtloid := TArray<_C_int>.Create( 1, 21 );
	sysctlMib[32].mCtlname := 'kern.bufcachepercent'; sysctlMib[32].mCtloid := TArray<_C_int>.Create( 1, 72 );
	sysctlMib[33].mCtlname := 'kern.ccpu'; sysctlMib[33].mCtloid := TArray<_C_int>.Create( 1, 45 );
	sysctlMib[34].mCtlname := 'kern.clockrate'; sysctlMib[34].mCtloid := TArray<_C_int>.Create( 1, 12 );
	sysctlMib[35].mCtlname := 'kern.consdev'; sysctlMib[35].mCtloid := TArray<_C_int>.Create( 1, 75 );
	sysctlMib[36].mCtlname := 'kern.cp_time'; sysctlMib[36].mCtloid := TArray<_C_int>.Create( 1, 40 );
	sysctlMib[37].mCtlname := 'kern.cp_time2'; sysctlMib[37].mCtloid := TArray<_C_int>.Create( 1, 71 );
	sysctlMib[38].mCtlname := 'kern.cryptodevallowsoft'; sysctlMib[38].mCtloid := TArray<_C_int>.Create( 1, 53 );
	sysctlMib[39].mCtlname := 'kern.domainname'; sysctlMib[39].mCtloid := TArray<_C_int>.Create( 1, 22 );
	sysctlMib[40].mCtlname := 'kern.file'; sysctlMib[40].mCtloid := TArray<_C_int>.Create( 1, 73 );
	sysctlMib[41].mCtlname := 'kern.forkstat'; sysctlMib[41].mCtloid := TArray<_C_int>.Create( 1, 42 );
	sysctlMib[42].mCtlname := 'kern.fscale'; sysctlMib[42].mCtloid := TArray<_C_int>.Create( 1, 46 );
	sysctlMib[43].mCtlname := 'kern.fsync'; sysctlMib[43].mCtloid := TArray<_C_int>.Create( 1, 33 );
	sysctlMib[44].mCtlname := 'kern.hostid'; sysctlMib[44].mCtloid := TArray<_C_int>.Create( 1, 11 );
	sysctlMib[45].mCtlname := 'kern.hostname'; sysctlMib[45].mCtloid := TArray<_C_int>.Create( 1, 10 );
	sysctlMib[46].mCtlname := 'kern.intrcnt.nintrcnt'; sysctlMib[46].mCtloid := TArray<_C_int>.Create( 1, 63, 1 );
	sysctlMib[47].mCtlname := 'kern.job_control'; sysctlMib[47].mCtloid := TArray<_C_int>.Create( 1, 19 );
	sysctlMib[48].mCtlname := 'kern.malloc.buckets'; sysctlMib[48].mCtloid := TArray<_C_int>.Create( 1, 39, 1 );
	sysctlMib[49].mCtlname := 'kern.malloc.kmemnames'; sysctlMib[49].mCtloid := TArray<_C_int>.Create( 1, 39, 3 );
	sysctlMib[50].mCtlname := 'kern.maxclusters'; sysctlMib[50].mCtloid := TArray<_C_int>.Create( 1, 67 );
	sysctlMib[51].mCtlname := 'kern.maxfiles'; sysctlMib[51].mCtloid := TArray<_C_int>.Create( 1, 7 );
	sysctlMib[52].mCtlname := 'kern.maxlocksperuid'; sysctlMib[52].mCtloid := TArray<_C_int>.Create( 1, 70 );
	sysctlMib[53].mCtlname := 'kern.maxpartitions'; sysctlMib[53].mCtloid := TArray<_C_int>.Create( 1, 23 );
	sysctlMib[54].mCtlname := 'kern.maxproc'; sysctlMib[54].mCtloid := TArray<_C_int>.Create( 1, 6 );
	sysctlMib[55].mCtlname := 'kern.maxthread'; sysctlMib[55].mCtloid := TArray<_C_int>.Create( 1, 25 );
	sysctlMib[56].mCtlname := 'kern.maxvnodes'; sysctlMib[56].mCtloid := TArray<_C_int>.Create( 1, 5 );
	sysctlMib[57].mCtlname := 'kern.mbstat'; sysctlMib[57].mCtloid := TArray<_C_int>.Create( 1, 59 );
	sysctlMib[58].mCtlname := 'kern.msgbuf'; sysctlMib[58].mCtloid := TArray<_C_int>.Create( 1, 48 );
	sysctlMib[59].mCtlname := 'kern.msgbufsize'; sysctlMib[59].mCtloid := TArray<_C_int>.Create( 1, 38 );
	sysctlMib[60].mCtlname := 'kern.nchstats'; sysctlMib[60].mCtloid := TArray<_C_int>.Create( 1, 41 );
	sysctlMib[61].mCtlname := 'kern.netlivelocks'; sysctlMib[61].mCtloid := TArray<_C_int>.Create( 1, 76 );
	sysctlMib[62].mCtlname := 'kern.nfiles'; sysctlMib[62].mCtloid := TArray<_C_int>.Create( 1, 56 );
	sysctlMib[63].mCtlname := 'kern.ngroups'; sysctlMib[63].mCtloid := TArray<_C_int>.Create( 1, 18 );
	sysctlMib[64].mCtlname := 'kern.nosuidcoredump'; sysctlMib[64].mCtloid := TArray<_C_int>.Create( 1, 32 );
	sysctlMib[65].mCtlname := 'kern.nprocs'; sysctlMib[65].mCtloid := TArray<_C_int>.Create( 1, 47 );
	sysctlMib[66].mCtlname := 'kern.nselcoll'; sysctlMib[66].mCtloid := TArray<_C_int>.Create( 1, 43 );
	sysctlMib[67].mCtlname := 'kern.nthreads'; sysctlMib[67].mCtloid := TArray<_C_int>.Create( 1, 26 );
	sysctlMib[68].mCtlname := 'kern.numvnodes'; sysctlMib[68].mCtloid := TArray<_C_int>.Create( 1, 58 );
	sysctlMib[69].mCtlname := 'kern.osrelease'; sysctlMib[69].mCtloid := TArray<_C_int>.Create( 1, 2 );
	sysctlMib[70].mCtlname := 'kern.osrevision'; sysctlMib[70].mCtloid := TArray<_C_int>.Create( 1, 3 );
	sysctlMib[71].mCtlname := 'kern.ostype'; sysctlMib[71].mCtloid := TArray<_C_int>.Create( 1, 1 );
	sysctlMib[72].mCtlname := 'kern.osversion'; sysctlMib[72].mCtloid := TArray<_C_int>.Create( 1, 27 );
	sysctlMib[73].mCtlname := 'kern.pool_debug'; sysctlMib[73].mCtloid := TArray<_C_int>.Create( 1, 77 );
	sysctlMib[74].mCtlname := 'kern.posix1version'; sysctlMib[74].mCtloid := TArray<_C_int>.Create( 1, 17 );
	sysctlMib[75].mCtlname := 'kern.proc'; sysctlMib[75].mCtloid := TArray<_C_int>.Create( 1, 66 );
	sysctlMib[76].mCtlname := 'kern.random'; sysctlMib[76].mCtloid := TArray<_C_int>.Create( 1, 31 );
	sysctlMib[77].mCtlname := 'kern.rawpartition'; sysctlMib[77].mCtloid := TArray<_C_int>.Create( 1, 24 );
	sysctlMib[78].mCtlname := 'kern.saved_ids'; sysctlMib[78].mCtloid := TArray<_C_int>.Create( 1, 20 );
	sysctlMib[79].mCtlname := 'kern.securelevel'; sysctlMib[79].mCtloid := TArray<_C_int>.Create( 1, 9 );
	sysctlMib[80].mCtlname := 'kern.seminfo'; sysctlMib[80].mCtloid := TArray<_C_int>.Create( 1, 61 );
	sysctlMib[81].mCtlname := 'kern.shminfo'; sysctlMib[81].mCtloid := TArray<_C_int>.Create( 1, 62 );
	sysctlMib[82].mCtlname := 'kern.somaxconn'; sysctlMib[82].mCtloid := TArray<_C_int>.Create( 1, 28 );
	sysctlMib[83].mCtlname := 'kern.sominconn'; sysctlMib[83].mCtloid := TArray<_C_int>.Create( 1, 29 );
	sysctlMib[84].mCtlname := 'kern.splassert'; sysctlMib[84].mCtloid := TArray<_C_int>.Create( 1, 54 );
	sysctlMib[85].mCtlname := 'kern.stackgap_random'; sysctlMib[85].mCtloid := TArray<_C_int>.Create( 1, 50 );
	sysctlMib[86].mCtlname := 'kern.sysvipc_info'; sysctlMib[86].mCtloid := TArray<_C_int>.Create( 1, 51 );
	sysctlMib[87].mCtlname := 'kern.sysvmsg'; sysctlMib[87].mCtloid := TArray<_C_int>.Create( 1, 34 );
	sysctlMib[88].mCtlname := 'kern.sysvsem'; sysctlMib[88].mCtloid := TArray<_C_int>.Create( 1, 35 );
	sysctlMib[89].mCtlname := 'kern.sysvshm'; sysctlMib[89].mCtloid := TArray<_C_int>.Create( 1, 36 );
	sysctlMib[90].mCtlname := 'kern.timecounter.choice'; sysctlMib[90].mCtloid := TArray<_C_int>.Create( 1, 69, 4 );
	sysctlMib[91].mCtlname := 'kern.timecounter.hardware'; sysctlMib[91].mCtloid := TArray<_C_int>.Create( 1, 69, 3 );
	sysctlMib[92].mCtlname := 'kern.timecounter.tick'; sysctlMib[92].mCtloid := TArray<_C_int>.Create( 1, 69, 1 );
	sysctlMib[93].mCtlname := 'kern.timecounter.timestepwarnings'; sysctlMib[93].mCtloid := TArray<_C_int>.Create( 1, 69, 2 );
	sysctlMib[94].mCtlname := 'kern.tty.maxptys'; sysctlMib[94].mCtloid := TArray<_C_int>.Create( 1, 44, 6 );
	sysctlMib[95].mCtlname := 'kern.tty.nptys'; sysctlMib[95].mCtloid := TArray<_C_int>.Create( 1, 44, 7 );
	sysctlMib[96].mCtlname := 'kern.tty.tk_cancc'; sysctlMib[96].mCtloid := TArray<_C_int>.Create( 1, 44, 4 );
	sysctlMib[97].mCtlname := 'kern.tty.tk_nin'; sysctlMib[97].mCtloid := TArray<_C_int>.Create( 1, 44, 1 );
	sysctlMib[98].mCtlname := 'kern.tty.tk_nout'; sysctlMib[98].mCtloid := TArray<_C_int>.Create( 1, 44, 2 );
	sysctlMib[99].mCtlname := 'kern.tty.tk_rawcc'; sysctlMib[99].mCtloid := TArray<_C_int>.Create( 1, 44, 3 );
	sysctlMib[100].mCtlname := 'kern.tty.ttyinfo'; sysctlMib[100].mCtloid := TArray<_C_int>.Create( 1, 44, 5 );
	sysctlMib[101].mCtlname := 'kern.ttycount'; sysctlMib[101].mCtloid := TArray<_C_int>.Create( 1, 57 );
	sysctlMib[102].mCtlname := 'kern.userasymcrypto'; sysctlMib[102].mCtloid := TArray<_C_int>.Create( 1, 60 );
	sysctlMib[103].mCtlname := 'kern.usercrypto'; sysctlMib[103].mCtloid := TArray<_C_int>.Create( 1, 52 );
	sysctlMib[104].mCtlname := 'kern.usermount'; sysctlMib[104].mCtloid := TArray<_C_int>.Create( 1, 30 );
	sysctlMib[105].mCtlname := 'kern.version'; sysctlMib[105].mCtloid := TArray<_C_int>.Create( 1, 4 );
	sysctlMib[106].mCtlname := 'kern.vnode'; sysctlMib[106].mCtloid := TArray<_C_int>.Create( 1, 13 );
	sysctlMib[107].mCtlname := 'kern.watchdog.auto'; sysctlMib[107].mCtloid := TArray<_C_int>.Create( 1, 64, 2 );
	sysctlMib[108].mCtlname := 'kern.watchdog.period'; sysctlMib[108].mCtloid := TArray<_C_int>.Create( 1, 64, 1 );
	sysctlMib[109].mCtlname := 'net.bpf.bufsize'; sysctlMib[109].mCtloid := TArray<_C_int>.Create( 4, 31, 1 );
	sysctlMib[110].mCtlname := 'net.bpf.maxbufsize'; sysctlMib[110].mCtloid := TArray<_C_int>.Create( 4, 31, 2 );
	sysctlMib[111].mCtlname := 'net.inet.ah.enable'; sysctlMib[111].mCtloid := TArray<_C_int>.Create( 4, 2, 51, 1 );
	sysctlMib[112].mCtlname := 'net.inet.ah.stats'; sysctlMib[112].mCtloid := TArray<_C_int>.Create( 4, 2, 51, 2 );
	sysctlMib[113].mCtlname := 'net.inet.carp.allow'; sysctlMib[113].mCtloid := TArray<_C_int>.Create( 4, 2, 112, 1 );
	sysctlMib[114].mCtlname := 'net.inet.carp.log'; sysctlMib[114].mCtloid := TArray<_C_int>.Create( 4, 2, 112, 3 );
	sysctlMib[115].mCtlname := 'net.inet.carp.preempt'; sysctlMib[115].mCtloid := TArray<_C_int>.Create( 4, 2, 112, 2 );
	sysctlMib[116].mCtlname := 'net.inet.carp.stats'; sysctlMib[116].mCtloid := TArray<_C_int>.Create( 4, 2, 112, 4 );
	sysctlMib[117].mCtlname := 'net.inet.divert.recvspace'; sysctlMib[117].mCtloid := TArray<_C_int>.Create( 4, 2, 258, 1 );
	sysctlMib[118].mCtlname := 'net.inet.divert.sendspace'; sysctlMib[118].mCtloid := TArray<_C_int>.Create( 4, 2, 258, 2 );
	sysctlMib[119].mCtlname := 'net.inet.divert.stats'; sysctlMib[119].mCtloid := TArray<_C_int>.Create( 4, 2, 258, 3 );
	sysctlMib[120].mCtlname := 'net.inet.esp.enable'; sysctlMib[120].mCtloid := TArray<_C_int>.Create( 4, 2, 50, 1 );
	sysctlMib[121].mCtlname := 'net.inet.esp.stats'; sysctlMib[121].mCtloid := TArray<_C_int>.Create( 4, 2, 50, 4 );
	sysctlMib[122].mCtlname := 'net.inet.esp.udpencap'; sysctlMib[122].mCtloid := TArray<_C_int>.Create( 4, 2, 50, 2 );
	sysctlMib[123].mCtlname := 'net.inet.esp.udpencap_port'; sysctlMib[123].mCtloid := TArray<_C_int>.Create( 4, 2, 50, 3 );
	sysctlMib[124].mCtlname := 'net.inet.etherip.allow'; sysctlMib[124].mCtloid := TArray<_C_int>.Create( 4, 2, 97, 1 );
	sysctlMib[125].mCtlname := 'net.inet.etherip.stats'; sysctlMib[125].mCtloid := TArray<_C_int>.Create( 4, 2, 97, 2 );
	sysctlMib[126].mCtlname := 'net.inet.gre.allow'; sysctlMib[126].mCtloid := TArray<_C_int>.Create( 4, 2, 47, 1 );
	sysctlMib[127].mCtlname := 'net.inet.gre.wccp'; sysctlMib[127].mCtloid := TArray<_C_int>.Create( 4, 2, 47, 2 );
	sysctlMib[128].mCtlname := 'net.inet.icmp.bmcastecho'; sysctlMib[128].mCtloid := TArray<_C_int>.Create( 4, 2, 1, 2 );
	sysctlMib[129].mCtlname := 'net.inet.icmp.errppslimit'; sysctlMib[129].mCtloid := TArray<_C_int>.Create( 4, 2, 1, 3 );
	sysctlMib[130].mCtlname := 'net.inet.icmp.maskrepl'; sysctlMib[130].mCtloid := TArray<_C_int>.Create( 4, 2, 1, 1 );
	sysctlMib[131].mCtlname := 'net.inet.icmp.rediraccept'; sysctlMib[131].mCtloid := TArray<_C_int>.Create( 4, 2, 1, 4 );
	sysctlMib[132].mCtlname := 'net.inet.icmp.redirtimeout'; sysctlMib[132].mCtloid := TArray<_C_int>.Create( 4, 2, 1, 5 );
	sysctlMib[133].mCtlname := 'net.inet.icmp.stats'; sysctlMib[133].mCtloid := TArray<_C_int>.Create( 4, 2, 1, 7 );
	sysctlMib[134].mCtlname := 'net.inet.icmp.tstamprepl'; sysctlMib[134].mCtloid := TArray<_C_int>.Create( 4, 2, 1, 6 );
	sysctlMib[135].mCtlname := 'net.inet.igmp.stats'; sysctlMib[135].mCtloid := TArray<_C_int>.Create( 4, 2, 2, 1 );
	sysctlMib[136].mCtlname := 'net.inet.ip.arpqueued'; sysctlMib[136].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 36 );
	sysctlMib[137].mCtlname := 'net.inet.ip.encdebug'; sysctlMib[137].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 12 );
	sysctlMib[138].mCtlname := 'net.inet.ip.forwarding'; sysctlMib[138].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 1 );
	sysctlMib[139].mCtlname := 'net.inet.ip.ifq.congestion'; sysctlMib[139].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 30, 4 );
	sysctlMib[140].mCtlname := 'net.inet.ip.ifq.drops'; sysctlMib[140].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 30, 3 );
	sysctlMib[141].mCtlname := 'net.inet.ip.ifq.len'; sysctlMib[141].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 30, 1 );
	sysctlMib[142].mCtlname := 'net.inet.ip.ifq.maxlen'; sysctlMib[142].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 30, 2 );
	sysctlMib[143].mCtlname := 'net.inet.ip.maxqueue'; sysctlMib[143].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 11 );
	sysctlMib[144].mCtlname := 'net.inet.ip.mforwarding'; sysctlMib[144].mCtloid := TArray<_C_int>.Create( 4, 2, 0, 31 );

end.
