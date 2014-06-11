#===============================================================================
# * Ammo Requirements * - VX Edition
#-------------------------------------------------------------------------------
# Written by Ty/Synthesize
# Version 1.2.5
# July 24, 2009
#-------------------------------------------------------------------------------
# * This script is only compatible with RGSS2 *
#===============================================================================
# Begin Customization
#-------------------------------------------------------------------------------
module TysAmmoRequirements
  #-----------------------------------------------------------------------------
  # * General Settings *
  #-----------------------------------------------------------------------------
    # Un-equip actor weapon when out of ammo.
    Unequip_weapon_NoAmmo = true
  #-----------------------------------------------------------------------------
  # * Weapon Ammunition Settings *
  #-----------------------------------------------------------------------------
    # This sets how much ammo is needed for a specific weapon ID in the database
    # Syntax = {weapon_id => ammunition_cost}
    Weapons_ammo_cost = {4 => 1, 5 => 1}
    # This assigns Item IDs in the database to a weapon ID
    # Syntax = {weapon_id => item_id}
    Weapons_ammo_id = {4 => [21,22], 5 => 22}
    # Creating weapons that use Multiple Ammunition is easy. You use the hash above
    # and create the Ammo like you normally would, however the syntax changes to this:
    # Syntax if using multiple Ammo = {Weapon_ID => [item_id1, item_id2, etc]}
  #-----------------------------------------------------------------------------
  # *Skill Ammunition Settings *
  #-----------------------------------------------------------------------------
    # This assigns the ammo cost for a specific skill ID
    # Syntax = {skill_id => ammo_cost}
    Skill_ammo_cost = {1 => 2}
    # This defines the Item ID used as ammunition for the Skill ID
    # syntax = {skill_id => Item_ID}
    Skill_ammo_id = {1 => 21}
  #-----------------------------------------------------------------------------
  # * Enemy Ammo Use Settings *
  #-----------------------------------------------------------------------------
    # This defines enemies that use ammunition. Simply put this tag in the 'Notes'
    # and the enemy will automatically use ammunition.
    Enemy_ammo_activate_string = "UseAmmo"
    # This defines enemy weapon/ammo names
    # Syntax: {enemy_id => "Name"}
    Enemy_ammo_name = {1 => "Jelly", 2 => "Arrow", 3 => "Pistol"}
    # This defines ammo cost when enemy uses skills
    # Syntax: skill_id -> ammo_cost
    Enemy_skill_cost = {1 => 5}
end
#-------------------------------------------------------------------------------
# Vocab Add-ons
#-------------------------------------------------------------------------------
module Vocab
  # Syntax: "[Actor_Name] used [ammo_cost] [ammo_name]"
  ConsumeAmmo = "%s used %s %s(s)!"
  # Syntax: "[Actor_Name] is out of [ammo_name}!"
  NoAmmo = "%s is out of %s(s)!"
  # Syntax: "[Enemy_Name] is out of [ammo_name}!"
  EnemyNoAmmo = "%s is out of %s!"
  # Syntax: "[Enemy_Name] used a [ammo_name}!"
  EnemyUsedAmmo = "%s used %s!"
end
#-------------------------------------------------------------------------------
# End Script Customization
#-------------------------------------------------------------------------------
# Begin Script
#-------------------------------------------------------------------------------
class Scene_Battle
  # Alias methods
  alias ty_ammo_requirements_attack execute_action_attack
  alias ty_ammo_requirements_start start
  alias ty_ammo_requirements_execute_action execute_action
  alias ty_ammo_requirements_execute_skill execute_action_skill
  #-----------------------------------------------------------------------------
  # Start:: Call a custom method
  #-----------------------------------------------------------------------------
  def start
    ty_ammo_requirements_start
    ty_set_enemy_ammo
  end
  #-----------------------------------------------------------------------------
  # Sets the enemy ammo requirement statistics
  #-----------------------------------------------------------------------------
  def ty_set_enemy_ammo
    @enemy_ammo = []
    @enemy_attack = -1
      for member in $game_troop.members
        if $data_enemies[member.enemy_id].note.include?(TysAmmoRequirements::Enemy_ammo_activate_string)
          total_ammo = $data_enemies[member.enemy_id].note.downcase.match('totalammo:(\d*)')[1].to_i
          @enemy_ammo.push(total_ammo)
        end
      end
  end
  #-----------------------------------------------------------------------------
  # Reset Enemy Index if it is the actors turn
  #-----------------------------------------------------------------------------
  def execute_action
    # This is a VERY lazy way for using different enemy ammo counts.
    # When it's the enemies turn, add one to enemy_attack. This acts as a index
    # For emoving enemy ammo. It's an extremely simple and lazy way :x
    if @active_battler.is_a?(Game_Actor)
      @enemy_attack = -1
    else
      @enemy_attack += 1
    end
    ty_ammo_requirements_execute_action
  end
  #-----------------------------------------------------------------------------
  # execute_action_attack: Call an additional method, and then call the original code
  #-----------------------------------------------------------------------------
  def execute_action_skill
    # Call a custom battle method
    ty_execute_action_skill
    # Call the original battle method if still attacking
    if @active_battler.action.kind == 1
      ty_ammo_requirements_execute_skill
    end
  end
  #-----------------------------------------------------------------------------
  # execute_action_attack: Call an additional method, and then call the original code
  #-----------------------------------------------------------------------------
  def execute_action_attack
    # Call a custom battle method
    ty_execute_action_attack
    # Call the original battle method if still attacking
    if @active_battler.action.kind == 0
      ty_ammo_requirements_attack
    end
  end
  #-----------------------------------------------------------------------------
  # ty_execute_action_attack: This method performs the 'Attacking' with ranged weapon
  # check and removes the ammo needed, if it is present.
  #-----------------------------------------------------------------------------
  def ty_execute_action_attack
    # Check to see if the current attacker is the actor and is using a weapon that needs ammo
    if @active_battler.is_a?(Game_Actor) && TysAmmoRequirements::Weapons_ammo_cost[@active_battler.weapon_id]
      # Both checks clear, so perform Ammo adjustments
      # First we collect some end-user options, like ammo cost and ammo ID.
      gather_ammo_cost = TysAmmoRequirements::Weapons_ammo_cost[@active_battler.weapon_id]
      # This handles multiple ammunition for the same weapon. First we check if the setting is an array
      if TysAmmoRequirements::Weapons_ammo_id[@active_battler.weapon_id].is_a?(Array)
        # Check passed, so now we store the array items
        array_items = TysAmmoRequirements::Weapons_ammo_id[@active_battler.weapon_id]
        # Now we check each ID in array_items and compare to see if we have enough ammo
        for index in array_items
          # Check to see if the actor has enough ammo
          if $game_party.item_number($data_items[index]) >= gather_ammo_cost
            # Check cleared, gather item ID and terminate check loop
            gather_ammo_item = $data_items[index]
            break
          end
        end
      else
        gather_ammo_item = $data_items[TysAmmoRequirements::Weapons_ammo_id[@active_battler.weapon_id]]
      end
      # Next we check to make sure the attacking actor has enough ammo
      if $game_party.item_number(gather_ammo_item) >= gather_ammo_cost
        # The check cleared, so perform ammo adjustments
        # Consume Ammunition
        $game_party.lose_item(gather_ammo_item, gather_ammo_cost)
        # Display text
        text = sprintf(Vocab::ConsumeAmmo, @active_battler.name, gather_ammo_cost, gather_ammo_item.name)
        @message_window.add_instant_text(text)
      else
        # Failed check, go into defense mode
        if TysAmmoRequirements::Unequip_weapon_NoAmmo
          @active_battler.change_equip_by_id(0,0)
        else
        text = sprintf(Vocab::NoAmmo, @active_battler.name, gather_ammo_item.name)
        @message_window.add_instant_text(text)
        @active_battler.action.kind = 1
        execute_action_guard
        end
      end
      # Perform a check to see if Active_Battler is a enemy and has ammo
    elsif @active_battler.is_a?(Game_Enemy) && $data_enemies[@active_battler.enemy_id].note.include?(TysAmmoRequirements::Enemy_ammo_activate_string)
      # Now we have to isolate the interger in the 'Note' string of the enemies
      # and then store the interger in a new local value for future use.
      enemy_ammo_cost = $data_enemies[@active_battler.enemy_id].note.downcase.match('ammocost:(\d*)')[1].to_i
      enemy_use_physical = true if $data_enemies[@active_battler.enemy_id].note.include?('usephysical')
      enemy_use_physical = false if $data_enemies[@active_battler.enemy_id].note.include?('usephysical') == false
      enemy_ammo_name = TysAmmoRequirements::Enemy_ammo_name[@active_battler.enemy_id]
      # Check to see if the enemy has enough ammo to attack
      if @enemy_ammo[@enemy_attack] >= enemy_ammo_cost
        # Check cleared, remove enemy ammo.
        text = sprintf(Vocab::EnemyUsedAmmo, @active_battler.name, enemy_ammo_name)
        @message_window.add_instant_text(text)
        @enemy_ammo[@enemy_attack] -= enemy_ammo_cost
      else
        # Check failed, put enemy in guard mode  
        if enemy_use_physical == false
          text = sprintf(Vocab::EnemyNoAmmo, @active_battler.name, enemy_ammo_name)
          @message_window.add_instant_text(text)
          @active_battler.action.kind = 1
          execute_action_guard
        end
      end
    end
  end
  #-----------------------------------------------------------------------------
  # ty_execute_action_skill: This method checks to see if the skill being used
  # requires ammunition.
  #-----------------------------------------------------------------------------
  def ty_execute_action_skill
    # Check to see if the current attacker is the actor and is using a weapon that needs ammo
    if @active_battler.is_a?(Game_Actor) && TysAmmoRequirements::Skill_ammo_cost[@active_battler.action.skill_id]
      if TysAmmoRequirements::Weapons_ammo_id[@active_battler.weapon_id].is_a?(Array)
        # Check passed, so now we store the array items
        array_items = TysAmmoRequirements::Weapons_ammo_id[@active_battler.weapon_id]
        # Now we check each ID in array_items and compare to see if we have enough ammo
        for index in array_items
          # Check to see if the actor has enough ammo
          if $game_party.item_number($data_items[index]) >= gather_ammo_cost
            # Check cleared, gather item ID and terminate check loop
            gather_ammo_item = $data_items[index]
            break
          end
        end
      else
        gather_ammo_item = $data_items[TysAmmoRequirements::Weapons_ammo_id[@active_battler.skill_id]]
      end
      # Both checks clear, so perform Ammo adjustments
      # First we collect some end-user options, like ammo cost and ammo ID.
      gather_ammo_cost = TysAmmoRequirements::Skill_ammo_cost[@active_battler.action.skill_id]
      id = @active_battler.action.skill_id
      gather_ammo_item =  $data_items[TysAmmoRequirements::Skill_ammo_id[id]]
      if $game_party.item_number(gather_ammo_item) >= gather_ammo_cost
        # The check cleared, so perform ammo adjustments
        # Consume Ammunition
        $game_party.lose_item(gather_ammo_item, gather_ammo_cost)
        # Display text
        text = sprintf(Vocab::ConsumeAmmo, @active_battler.name, gather_ammo_cost, gather_ammo_item.name)
        @message_window.add_instant_text(text)
      else
        # Failed check, go into defense mode
        text = sprintf(Vocab::NoAmmo, @active_battler.name, gather_ammo_item.name)
        @message_window.add_instant_text(text)
        @active_battler.action.kind = 0
        execute_action_guard
      end
      # Perform a check to see if Active_Battler is a enemy and has ammo
    elsif @active_battler.is_a?(Game_Enemy) && $data_enemies[@active_battler.enemy_id].note.include?(TysAmmoRequirements::Enemy_ammo_activate_string) && TysAmmoRequirements::Enemy_skill_cost[@active_battler.action.skill_id]
      # Now we have to isolate the interger in the 'Note' string of the enemies
      # and then store the interger in a new local value for future use.
      enemy_ammo_cost = TysAmmoRequirements::Enemy_skill_cost[@active_battler.action.skill_id]
      enemy_ammo_name = TysAmmoRequirements::Enemy_ammo_name[@active_battler.enemy_id]
      # Check to see if the enemy has enough ammo to attack
      if @enemy_ammo[@enemy_attack] >= enemy_ammo_cost
        # Check cleared, remove enemy ammo.
        text = sprintf(Vocab::EnemyUsedAmmo, @active_battler.name, enemy_ammo_name)
        @message_window.add_instant_text(text)
        @enemy_ammo[@enemy_attack] -= enemy_ammo_cost
      else
        # Check failed, put enemy in guard mode  
        text = sprintf(Vocab::EnemyNoAmmo, @active_battler.name, enemy_ammo_name)
        @message_window.add_instant_text(text)
        @active_battler.action.kind = 0
        execute_action_guard
      end
    end
  end
end