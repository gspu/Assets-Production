"DO NOT RUN THIS!!!!!!"
//module contraband_mission {
	import ai_stationary;
	import universe;
	object youcontainer;
	object jump_point;
	object jumpcontainer;
	object cargoname;
	int stage;
	int nr_waves;
	float dist;
	int nr_ships;
	float cred;
	import random;
	import launch;
	import faction_ships;



	void init (object cargo, float distance, float creds, int nr_ships, int nr_waves) {
		faction_ships.init();
		faction=faction_ships.intToFaction(random.randint(0,2));
		arrived=false;
		cred=creds;
		distfrombase=distance_from_base;
		difficulty=missiondifficulty;
		object mysys=_std.getSystemFile();
		quantity=cargoquantity;
		object sysfile = _std.getSystemFile();
		object you=_unit.getPlayer();
		youcontainer=_unit.getContainer (you);
		if (quantity<1){
			quantity=1;
		}
		object list=_unit.getRandCargo(quantity);
		int tempquantity=quantity;
		cargoname=_olist.at(list,0);
		object str = _string.new();
		if (!_std.isNull(you)) {
			quantity = _unit.addCargo(you,cargoname,_olist.at(list,1),_olist.at(list,2),_olist.at(list,3),_olist.at(list,4),_olist.at(list,5));  //ADD CARGO HERE
			object name = _unit.getName (you);
			_io.sprintf(str,"Good Day, %s. Your mission is as follows:",name);
		} else {
			_std.terminateMission (false);
			return;
		}
		if (tempquantity>0) {
			cred=cred *_std.Float(quantity)/_std.Float(tempquantity);
		}
		_io.message (0,"game","all",str);
		destination=universe.getAdjacentSystem(sysfile,numsystemsaway);
		_io.sprintf(str,"and give the cargo to a %s unit.",faction);
		_io.message (2,"game","all",str);
		_io.sprintf(str,"You will receive %d of the %s cargo",quantity,cargoname);
		_io.message (3,"game","all",str);
		_string.delete(str);
		_olist.delete(list);
	};
	void takeCargoAndTerminate (object you) {
		int removenum=_unit.removeCargo(you,cargoname,quantity,true);
		if ((removenum==quantity)||(quantity==0)) {
			_io.message (0,"game","all","Excellent work pilot.");
			_io.message (0,"game","all","You have been rewarded for your effort as agreed.");
			_io.message (0,"game","all","Your contribution to the war effort will be remembered.");
			_unit.addCredits(you,cred);
			_std.terminateMission(true);
			return;
		} else {
			_io.message (0,"game","all","You did not follow through on your end of the deal.");

			if (difficulty<1) {
				_io.message (0,"game","all","Your pay will be reduced");
				_io.message (0,"game","all","And we will consider if we will accept you on future missions.");
				float addcred=(_std.Float(removenum)/_std.Float((quantity*(1+difficulty))))*cred;
				_unit.addCredits(you,addcred);
			} else {
				_io.message (0,"game","all","You will not be paid!");
				if (difficulty>=2) {
					_io.message (0,"game","all","And your idiocy will be punished.");
					_io.message (0,"game","all","You had better run for what little life you have left.");
					int i=0;
					object un;
					while (i<difficulty) {
						un=faction_ships.getRandomFighter(faction);
						object newunit=launch.launch_wave_around_unit("shadow", faction, un, "default", 1, 1000.0,you);
						_unit.setTarget(newunit,you);
						i=i+1;
					}
				}
			}
			_std.terminateMission(false);
			return;
		}
	};
	void loop () {
		if (arrived) {
			object base=_unit.getUnitFromContainer(basecontainer);
			object you=_unit.getUnitFromContainer(youcontainer);
	};
}
