#!/bin/bash

AXIOM_PATH="$HOME/.axiom"

###################################################################
#  Create many instance at a time
#
#  needed for axiom-fleet
create_instances() {
	start="$1"
	end="$2"
        gen_name="$3"
        image_id="$4"
        size_slug="$5"
        region="$6"
        sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
        do_key="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.do_key')"
        sshkey_fingerprint="$(ssh-keygen -l -E md5 -f ~/.ssh/$sshkey.pub | awk '{print $2}' | cut -d : -f 2-)"
        keyid=$(doctl compute ssh-key import $sshkey \
         --public-key-file ~/.ssh/$sshkey.pub \
         --format ID \
         --no-header 2>/dev/null) ||
        keyid=$(doctl compute ssh-key list | grep "$sshkey_fingerprint" | awk '{ print $1 }')

       doctl compute droplet create $(for i in $(seq $start $end); do echo $gen_name$i | tr '\n' ' '; done) --image "$image_id" --size "$slug" --region "$region" --enable-ipv6 --ssh-keys "$keyid"
       sleep 20
       instances_ready $gen_name $start $end
}

###################################################################
#  Create one instance at a time
#
#  needed for axiom-init
create_instance() {
        name="$1"
        image_id="$2"
        size_slug="$3"
        region="$4"
        sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
        sshkey_fingerprint="$(ssh-keygen -l -E md5 -f ~/.ssh/$sshkey.pub | awk '{print $2}' | cut -d : -f 2-)"
        keyid=$(doctl compute ssh-key import $sshkey \
         --public-key-file ~/.ssh/$sshkey.pub \
         --format ID \
         --no-header 2>/dev/null) ||
        keyid=$(doctl compute ssh-key list | grep "$sshkey_fingerprint" | awk '{ print $1 }')

        doctl compute droplet create "$name" --image "$image_id" --size "$size" --region "$region" --enable-ipv6 --ssh-keys "$keyid" >/dev/null
        sleep 260
}

###################################################################
# deletes instance, if the second argument is set to "true", will not prompt
# used by axiom-rm
#
delete_instance() {
        name="$1"
        force="$2"

        if [ "$force" == "true" ]
        then
         doctl compute droplet delete -f "$name"
        else
        doctl compute droplet delete "$name"
        fi
}

###################################################################
# Instances functions
# used by many functions in this file
instances() {
        doctl compute droplet list -o json
}

# takes one argument, name of instance, returns raw IP address
# used by axiom-ls axiom-init
instance_ip() {
        name="$1"
        instances | jq -r ".[]? | select(.name==\"$name\") | .networks.v4[]? | select(.type==\"public\") | .ip_address" | head -1
}

# check if instance name is in .sshconfig
# used by axiom-scan
instance_ip_cache() {
        name="$1"
        config="$2"
        ssh_config="$AXIOM_PATH/.sshconfig"

        if [[ "$config" != "" ]]; then
         ssh_config="$config"
        fi

        cat "$ssh_config" | grep -A 1 "$name" | awk '{ print $2 }' | tail -n 1
}

# used by axiom-select axiom-ls
instance_list() {
        instances | jq -r '.[].name'
}

# used by axiom-ls
instance_pretty() {
        data=$(instances)

        #number of droplets
        droplets=$(echo $data|jq -r '.[]|.name'|wc -l )



        i=0
        for f in $(echo $data | jq -r '.[].size.price_monthly'); do new=$(expr $i + $f); i=$new; done
        totalPrice=$i
        header="Instance,Primary Ip,Backend Ip,Region,Size,Status,\$/M"

	fields=".[] | [.name, (try (.networks.v4[] | select(.type==\"public\") | .ip_address) catch \"N/A\"),  (try (.networks.v4[] | select(.type==\"private\") | .ip_address) catch \"N/A\"), .region.slug, .size_slug, .status, .size.price_monthly] | @csv"

        totals="_,_,_,Instances,$droplets,Total,\$$totalPrice"
        #data is sorted by default by field name
        data=$(echo $data | jq  -r "$fields")
        (echo "$header" && echo "$data" && echo $totals) | sed 's/"//g' | column -t -s, 
}

###################################################################
#  Dynamically generates axiom's SSH config based on your cloud inventory
#  Choose between generating the sshconfig using private IP details, public IP details or optionally lock
#  Lock will never generate an SSH config and only used the cached config ~/.axiom/.sshconfig 
#  Used for axiom-exec axiom-fleet axiom-ssh
#
generate_sshconfig() {
	accounts=$(ls -l "$AXIOM_PATH/accounts/" | grep "json" | grep -v 'total ' | awk '{ print $9 }' | sed 's/\.json//g')
	current=$(readlink -f "$AXIOM_PATH/axiom.json" | rev | cut -d / -f 1 | rev | cut -d . -f 1)> /dev/null 2>&1
	sshnew="$AXIOM_PATH/.sshconfig.new$RANDOM"
	droplets="$(instances)"
	echo -n "" > $sshnew
	echo -e "\tServerAliveInterval 60\n" >> $sshnew
	sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
	echo -e "IdentityFile $HOME/.ssh/$sshkey" >> $sshnew
	generate_sshconfig="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.generate_sshconfig')"

	if [[ "$generate_sshconfig" == "private" ]]; then

	 echo -e "Warning your SSH config generation toggle is set to 'Private' for account : $(echo $current)."
	 echo -e "axiom will always attempt to SSH into the instances from their private backend network interface. To revert run: axiom-ssh --just-generate"
	  for name in $(echo "$droplets" | jq -r '.[].name')
	  do
	   ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .networks.v4[] | select(.type==\"private\") | .ip_address" | head -1)
	   if [[ -n "$ip" ]]; then
	    echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew
	   fi
          done
	 mv $sshnew $AXIOM_PATH/.sshconfig

	elif [[ "$generate_sshconfig" == "cache" ]]; then
	 echo -e "Warning your SSH config generation toggle is set to 'Cache' for account : $(echo $current)."
	 echo -e "axiom will never attempt to regenerate the SSH config. To revert run: axiom-ssh --just-generate"

	 # If anything but "private" or "cache" is parsed from the generate_sshconfig in account.json, generate public IPs only
	 #
	  else
	   for name in $(echo "$droplets" | jq -r '.[].name')
	   do
	    ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .networks.v4[] | select(.type==\"public\") | .ip_address" | head -1)
	    if [[ -n "$ip" ]]; then
	     echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew
	    fi
	  done
	 mv $sshnew $AXIOM_PATH/.sshconfig
	fi
}

###################################################################
# takes any number of arguments, each argument should be an instance or a glob, say 'omnom*', returns a sorted list of instances based on query
# $ query_instances 'john*' marin39
# Resp >>  john01 john02 john03 john04 nmarin39
# used by axiom-ls axiom-select axiom-fleet axiom-rm axiom-power
#
query_instances() {
	droplets="$(instances)"
	selected=""

	for var in "$@"; do
	 if [[ "$var" =~ "*" ]]
	 then
	  var=$(echo "$var" | sed 's/*/.*/g')
	  selected="$selected $(echo $droplets | jq -r '.[].name' | grep "$var")"
	 else
	  if [[ $query ]];
	  then
	   query="$query\|$var"
	  else
	   query="$var"
	  fi
	 fi
	done

	if [[ "$query" ]]
	then
	 selected="$selected $(echo $droplets | jq -r '.[].name' | grep -w "$query")"
	else
	 if [[ ! "$selected" ]]
	 then
	  echo -e "${Red}No instance supplied, use * if you want to delete all instances...${Color_Off}"
	  exit
	 fi
	fi

	selected=$(echo "$selected" | tr ' ' '\n' | sort -u)
	echo -n $selected
}

###################################################################
# 
# used by axiom-scan axiom-exec axiom-scp
query_instances_cache() {
	selected=""
	ssh_conf="$AXIOM_PATH/.sshconfig"

	for var in "$@"; do
	if [[ "$var" =~ "-F=" ]]; then
	 ssh_conf="$(echo "$var" | cut -d "=" -f 2)"
	elif [[ "$var" =~ "*" ]]; then
	 var=$(echo "$var" | sed 's/*/.*/g')
	 selected="$selected $(cat "$ssh_conf" | grep "Host " | awk '{ print $2 }' | grep "$var")"
	else
	 if [[ $query ]];
	 then
	  query="$query\|$var"
	 else
	  query="$var"
	 fi
	fi
	done

	if [[ "$query" ]]
	then
	 selected="$selected $(cat "$ssh_conf" | grep "Host " | awk '{ print $2 }' | grep -w "$query")"
	else
 	 if [[ ! "$selected" ]]
	 then
	  echo -e "${Red}No instance supplied, use * if you want to delete all instances...${Color_Off}"
	  exit
	 fi
	fi

	selected=$(echo "$selected" | tr ' ' '\n' | sort -u)
	echo -n $selected
}

###################################################################
#
# used by axiom-fleet axiom-init
get_image_id() {
        query="$1"
        images=$(doctl compute snapshot list -o json)
        name=$(echo $images | jq -r ".[].name" | grep -wx "$query" | tail -n 1)
        id=$(echo $images |  jq -r ".[] | select(.name==\"$name\") | .id")
        echo $id
}

###################################################################
# Manage snapshots
# used for axiom-images and axiom-backup
#
snapshots() {
        doctl compute snapshot list -o json
}

# axiom-images
get_snapshots()
{
        doctl compute snapshot list
}

# axiom-images
delete_snapshot() {
        name="$1"
        image_id=$(get_image_id "$name")
        doctl compute snapshot delete "$image_id" -f
}

# axiom-images
create_snapshot() {
        instance="$1"
	snapshot_name="$2"
	doctl compute droplet-action snapshot "$(instance_id $instance)" --snapshot-name "$snapshot_name"
}

###################################################################
# Get data about regions
# used by axiom-regions
list_regions() {
    doctl compute region list
}

# used by axiom-regions
regions() {
    doctl compute region list -o json | jq -r '.[].slug'
}

###################################################################
#  Manage power state of instances
#  Used for axiom-power
#
poweron() {
        instance_name="$1"
        doctl compute droplet-action power-on $(instance_id $instance_name)
}

# axiom-power
poweroff() {
        instance_name="$1"
        doctl compute droplet-action power-off $(instance_id $instance_name)
}

# axiom-power
reboot(){
        instance_name="$1"
        doctl compute droplet-action reboot $(instance_id $instance_name)
}

# axiom-power axiom-images
instance_id() {
        name="$1"
        instances | jq ".[] | select(.name==\"$name\") | .id"
}

###################################################################
#  List available instance sizes
#  Used by ax sizes
#
sizes_list() {
   doctl compute size list
}
