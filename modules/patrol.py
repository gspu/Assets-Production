from go_to_adjacent_systems import *
import random
import launch
import faction_ships
import VS
import Briefing
import universe
import unit
import Director
class patrol (Director.Mission):
    def __init__ (self,numsystemsaway, num_significants_to_patrol, distance_from_base, creds):
          Director.Mission.__init__(self)
	  self.patrolpoints = []
          self.objectives = []
	  self.distance = distance_from_base
	  self.you = VS.getPlayer()
          self.quantity=num_significants_to_patrol
          name = self.you.getName ()
          self.mplay=universe.getMessagePlayer(self.you)
	  VS.IOmessage (0,"defend",self.mplay,"Greetings, %s. You must patrol a system for us :" % name)
          self.adjsys = go_to_adjacent_systems(self.you,numsystemsaway)
          self.adjsys.Print("From the %s system,","Carefully go to %s.","You should shortly arrive in the %s: patrol it.","patrol",1)
          
    def SuccessMission (self):
        self.you.addCredits (self.cred)
        VS.IOmessage (0,"computer",self.mplay,"[Computer] Transmitting Data..")
        VS.IOmessage (0,"patrol",self.mplay,"Thank you! Patrol Complete.")
        VS.IOmessage (0,"patrol",self.mplay,"We have credited your account.")
        VS.terminateMission(1)
        
    def GeneratePatrolList (self):
        VS.IOmessage (0,"patrol",self.mplay,"You must get within %f klicks of" % self.distance)
        count=self.quantity*2
        str=""
        while (self.quantity>0 and count > 0):
            count -= 1
	    sig = unit.getSignificant (random.randrange (0,128),0,0)
            if (not sig.isNull()):
                if (not (sig in patrol)):
                    self.patrolpoints += [sig]
                    self.quantity=self.quantity-1
                    fac =sig.getFactionName()
                    nam =sig.getName ()
                    if (fac!="neutral"):
                        obj=VS.addObjective ("Scan %s's object %s"% (fac,name))
                        str+=("%s owned %s " % (fac,nam))
                    else:
                        if (sig.isPlanet()):
                            obj=VS.addObjective ("Scan Planet %s"% (fac,name))
                        else:
                            obj=VS.addObjective ("Scan Natural Phenomenon: %s"% (fac,name))
                        str+=("%s" % nam)
                    VS.setOwner(obj,self.you)
                    VS.setCompleteness(obj,-1.0)
                    self.objectives+=[obj]
                    
        self.quantity=0
        VS.IOmessage (0,"patrol",self.mplay,str)
    def DeletePatrolPoint (num,nam):
        VS.IOmessage (0,"patrol",self.mplay,"[Computer] %s scanned, data saved..."%nam)
        VS.setCompleteness(self.objectives[self.jnum],1.0)
        del self.objectives[self.jnum]        
        del self.patrolpoints[self.jnum]
    def FinishedPatrol (self):
        if (self.jnum<len(self.patrolpoints)):
	    jpoint =self.patrolpoints[self.jnum]
            if (jpoint.isNull()):
                DeletePatrolpoint(self.jnum,"Debris")
            else:
	      if (self.you.getSignificantDistance (jpoint)<self.distance):
                  DeletePatrolPoint(self.jnum,jpoint.getName())
              else:
                  jnum+=1                  
        else:
	    jnum=0
        return (len(self.patrolpoints)==0)
    def Execute ():
        if (self.you.isNull()):
            VS.terminateMission(0)
        if (self.adjsys.Execute()):
            if (self.quantity>0):
		self.GeneratePatrolList ()
            else:
		if (self.FinishedPatrol()):
                    self.SuccessMission()

