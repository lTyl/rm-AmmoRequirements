#============================================================================
#                            Syn's Ammo Requirements  
#----------------------------------------------------------------------------
# Written by Synthesize
# Version 1.00
# August 15, 2007
# Tested with SDK 2.1
#============================================================================
#----------------------------------------------------------------------------
# Customization Section
#----------------------------------------------------------------------------
module Ammo
  # Format = {weapon_id => Ammo_cost}
  Range_weapons_id = {1 => 1, 2 => 2, 3 => 2, 4 => 5}
  # Format = {weapon_id => Item_id}
  Range_ammo_id = {1 => 6, 2 => 6, 3 => 6, 4 => 6}
  # Format = {skill_id => Ammo_cost}
  Skill_ammo = {1 => 1, 2 => 2, 3 => 2, 4 => 5}
  # Note on Skills: When using Skills the Current Ammo for the equipped 
  # weapon will be used. So if Skill 73 is used and Weapon 17 is equipped
  # then Ammo #33 will be used.
end
#----------------------------------------------------------------------------
# Begin Scene_Battle
#----------------------------------------------------------------------------
class Scene_Battle
  # Alias Methods
  alias syn_scene_battle_range make_basic_action_result
  alias syn_scene_battle_skill make_skill_action_result
  #----------------------------------------------------
  # Alias the Attacking method
  #----------------------------------------------------
  def make_basic_action_result
    # Gather the current Ammo Cost
    gather_ammo_cost = Ammo::Range_weapons_id[@active_battler.weapon_id]
    # Gather the Current Ammo
    gather_ammo = Ammo::Range_ammo_id[@active_battler.weapon_id]
    # Check if the Active Battler is attacking and if they are using a ranged weapon
    if @active_battler.current_action.basic == 0 and Ammo::Range_weapons_id.has_key?(@active_battler.weapon_id)
      # Check the Ammo Count
      if $game_party.item_number(gather_ammo) >= gather_ammo_cost
        # Sufficient Ammo, remove item
        $game_party.lose_item(gather_ammo,gather_ammo_cost)
        syn_scene_battle_range
      else
        # Insufficient Ammo
        @help_window.set_text("#{@active_battler.name} cannot attack due to insufficient Ammo", 1)
      end
      # Call Default Code
    else
      syn_scene_battle_range
    end
  end
  #----------------------------------------------------
  # Alias the Skill method
  #----------------------------------------------------
  def make_skill_action_result
    # Gather the current Ammo Cost
    gather_ammo_cost = Ammo::Skill_ammo[@active_battler.current_action.skill_id]
    # Gather Ammo
    gather_ammo = Ammo::Range_ammo_id[@active_battler.weapon_id]
    # Check if the Actor is using a defiend skill
    if Ammo::Skill_ammo.has_key?(@active_battler.current_action.skill_id)
      # Check if Ammo is present
      if $game_party.item_number(gather_ammo) >= gather_ammo_cost
        # Sufficient Ammo, remove item
        $game_party.lose_item(gather_ammo,gather_ammo_cost)
        # Call Default Code
        syn_scene_battle_skill
      else
        # Set Window; Do Nothing
        @help_window.set_text("#{@active_battler.name} cannot attack due to insufficient Ammo", 1)
      end
      # Otherwise SKip the check and call default code
    else
      syn_scene_battle_skill
    end
  end
end
#============================================================================
# Written by Synthesize
# Special Thanks: ~Emo~ for the request
#----------------------------------------------------------------------------
#                            Ammo Requirements
#============================================================================