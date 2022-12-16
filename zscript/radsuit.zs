//-------------------------------------------------
// Environment/Radiation Suit
//-------------------------------------------------
class WornRadsuit:HDDamageHandler{
	default{
		+nointeraction;+noblockmap;
		+hdpickup.fullcoverage
		inventory.maxamount 1;inventory.amount 1;
		HDDamageHandler.priority 1000;
		HDPickup.wornlayer STRIP_RADSUIT;
		HDPickup.overlaypriority 150;
		tag "environment suit";
	}
	states{spawn:TNT1 A 0;stop;}
	override inventory createtossable(int amt){
		let rrr=owner.findinventory("PortableRadsuit");
		if(rrr)owner.useinventory(rrr);else destroy();
		return null;
	}
	override void attachtoowner(actor owner){
		if(!owner.countinv("PortableRadsuit"))owner.A_GiveInventory("PortableRadsuit");
		super.attachtoowner(owner);
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("PortableRadsuit",1);
		HDArmour.ArmourChangeEffect(owner);
		super.DetachFromOwner();
	}
	override void DoEffect(){
		if(stamina>0)stamina--;
	}
	override double RestrictSpeed(double speedcap){
		return min(speedcap,1.8);
	}
	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		sb.SetSize(0,320,200);
		sb.BeginHUD(forcescaled:true);	
        int MaskHeight = int(Screen.GetHeight() * 2.2);
        int MaskWidth = int(Screen.GetWidth() * MaskHeight * 1.2) / Screen.GetHeight();
        int MaskOffX = -((MaskWidth - Screen.GetWidth()) >> 1);
		int MaskOffY = -((MaskHeight - Screen.GetHeight()) >> 1);
        Screen.DrawTexture(TexMan.CheckForTexture("DESPMASK"), true, MaskOffX - (int(hpl.wepbob.x * 0.5)), MaskOffY - (int(hpl.wepbob.y * 0.5)), DTA_DestWidth, MaskWidth, DTA_DestHeight, MaskHeight);
		/*sb.fill(
			color(sb.blurred?(level.time&(1|2|4))<<2:160,10,40,14),
			0,0,screen.getwidth(),screen.getheight()
		);*/
	}
	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		bool am=hdflags&HDSB_AUTOMAP;
		sb.drawimage(
			"SUITC0",
			am?(11,137):(64,-4),
			am?sb.DI_TOPLEFT:
			(sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER_BOTTOM)
		);
	}

	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int,name,int,double,int,int,int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double towound,
		int toburn,
		int tostun,
		int tobreak
	){
		let victim=owner;
		if(
			(flags&DMG_NO_ARMOR)
			||mod=="maxhpdrain"
			||mod=="internal"
			||mod=="jointlock"
			||mod=="bleedout"
			||!victim
		)return damage,mod,flags,towound,toburn,tostun,tobreak;


		if(
			mod!="bashing"
			&&mod!="falling"
		)stamina+=random(1,damage);


		bool breached=false;

		if(mod=="slime"){
			victim.A_SetInventory("Heat",countinv("Heat")+max(0,damage-random(4,20)));
			if(
				damage>10
				&&stamina>2100
			){
				breached=true;
			}else damage=0;
		}else if(
			mod=="hot"
			||mod=="cold"
		){
			if(damage<random(0,21))damage=0;
			else{
				int olddamage=damage>>1;
				damage=olddamage>>2;
				if(!damage&&random(0,olddamage))damage=1;
				if(stamina>2100)breached=true;
			}
		}else if(mod=="electrical"){
			if(damage>random(60,200))breached=true;
			int olddamage=damage>>2;
			damage=olddamage>>3;
			if(!damage&&random(0,olddamage))damage=1;
		}else if(mod=="slashing"){
			if(damage>random(5,30)){
				A_StartSound("radsuit/rip",CHAN_BODY,CHANF_OVERLAP);
				breached=true;
			}
		}else if(
			mod=="teeth"
			||mod=="claws"
			||mod=="natural"
		){
			if(random(1,damage)>10){
				A_StartSound("radsuit/rip",CHAN_BODY,CHANF_OVERLAP);
				breached=true;
				damage-=5;
			}
		}else{
			//any other damage not taken care of above
			if(towound>random(4,20))breached=true;
		}

		if(breached)destroyradsuit();

		return damage,mod,flags,towound,toburn,tostun,tobreak;
	}
	void DestroyRadsuit(){	
		destroy();
		if(owner){
			owner.A_TakeInventory("PowerIronFeet");
			owner.A_StartSound("radsuit/burst",CHAN_BODY,CHANF_OVERLAP);
		}
	}

	//called from HDBulletActor's OnHitActor
	override double,double OnBulletImpact(
		HDBulletActor bullet,
		double pen,
		double penshell,
		double hitangle,
		double deemedwidth,
		vector3 hitpos,
		vector3 vu,
		bool hitactoristall
	){
		if(pen>frandom(1,4))destroyradsuit();
		else{
			owner.damagemobj(
				bullet,bullet.target,
				int(pen*bullet.mass)>>10,
				"bashing"
			);
			pen=frandom(0.001,1);
			bullet.vel=vu*frandom(0.01,0.1);
			bullet.bmissile=false;
		}

		return pen,penshell+2;
	}

}
class PortableRadsuit:HDPickup replaces RadSuit{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Environment Suit"
		//$Sprite "SUITA0"

		inventory.pickupmessage "Environmental shielding suit.";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "SUITB0";
		hdpickup.bulk 20;
		tag "environment suit";
		hdpickup.refid HDLD_RADSUIT;
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("PortableRadsuit");
		owner.A_TakeInventory("WornRadsuit");
		target=owner;
		super.DetachFromOwner();
	}
	override inventory CreateTossable(int amt){
		if(
			amount<2
			&&owner.findinventory("WornRadsuit")
		){
			owner.UseInventory(self);
			return null;
		}
		return super.CreateTossable(amt);
	}
	override bool BeforePockets(actor other){
		//put on the armour right away
		if(
			other.player
			&&other.player.cmd.buttons&BT_USE
			&&!other.findinventory("WornRadsuit")
		){
			wornlayer=STRIP_RADSUIT;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			HDArmour.ArmourChangeEffect(other,120);
			let onr=HDPlayerPawn(other);
			int fff=HDF.TransferFire(other,other);
			if(fff){
				if(random(1,fff)>30){
					other.A_StartSound("misc/fwoosh",CHAN_BODY,CHANF_OVERLAP);
					destroy();
					return true;
				}else{
					HDF.TransferFire(self,other);
					if(onr){
						onr.fatigue+=fff;
						onr.stunned+=fff;
					}
				}
			}
			other.A_GiveInventory("PortableRadsuit");
			other.A_GiveInventory("WornRadsuit");
			destroy();
			return true;
		}
		return false;
	}
	override void DoEffect(){
		bfitsinbackpack=(amount!=1||!owner||!owner.findinventory("WornRadsuit"));
		super.doeffect();
	}
	states{
	spawn:
		SUIT A 1;
		SUIT A -1{
			if(!target)return;
			HDF.TransferFire(target,self);
		}
	use:
		TNT1 A 0{
			let owrs=wornradsuit(findinventory("wornradsuit"));
			if(owrs){
				if(!HDPlayerPawn.CheckStrip(self,owrs))return;
			}else{
				invoker.wornlayer=STRIP_RADSUIT+1;
				if(!HDPlayerPawn.CheckStrip(self,invoker)){
					invoker.wornlayer=0;
					return;
				}
				invoker.wornlayer=0;
			}

			HDArmour.ArmourChangeEffect(self,120);
			let onr=HDPlayerPawn(self);
			if(!countinv("WornRadsuit")){
				int fff=HDF.TransferFire(self,self);
				if(fff){
					if(random(1,fff)>30){
						A_StartSound("misc/fwoosh",CHAN_BODY,CHANF_OVERLAP);
						A_TakeInventory("PortableRadsuit",1);
						return;
					}else{
						HDF.TransferFire(self,null);
						if(onr){
							onr.fatigue+=fff;
							onr.stunned+=fff;
						}
					}
				}
				A_GiveInventory("WornRadsuit");
			}else{
				actor a;int b;
				inventory wrs=findinventory("wornradsuit");
				[b,a]=A_SpawnItemEx("PortableRadsuit",0,0,height*0.5,0.2,0,2);
				if(a && wrs){
					//transfer sticky fire
					if(wrs.stamina){
						let aa=HDActor(a);
						if(aa)aa.A_Immolate(a,self,wrs.stamina);
					}
					//transfer heat
					let hhh=heat(findinventory("heat"));
					if(hhh){
						double realamount=hhh.realamount;
						double intosuit=clamp(realamount*0.9,0,min(200,realamount));
						let hhh2=heat(a.GiveInventoryType("heat"));
						if(hhh2){
							hhh2.realamount+=intosuit;
							hhh.realamount=max(0,hhh.realamount-intosuit);
						}
					}
					vel.z+=0.2;
					vel.xy+=(cos(angle),sin(angle))*0.7;
				}
				A_TakeInventory("WornRadsuit");
			}
			if (player)
			{
				player.crouchfactor=min(player.crouchfactor,0.7);
			}
		}fail;
	}
}
