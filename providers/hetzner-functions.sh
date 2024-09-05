#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
LOG="$AXIOM_PATH/log.txt"

###################################################################
#  Create Instance is likely the most important provider function :)
#  needed for init and fleet
#
create_instance() {
	name="$1"
	image_id="$2"
	size_slug="$3"
	region="$4"

        sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
        sshkey_fingerprint="$(ssh-keygen -l -E md5 -f ~/.ssh/$sshkey.pub | awk '{print $2}' | cut -d : -f 2-)"
        keyid=$(hcloud ssh-key create --name $sshkey \
         --public-key-from-file ~/.ssh/$sshkey.pub 2>/dev/null) ||
         keyid=$(hcloud ssh-key list | grep "$sshkey_fingerprint" | awk '{ print $1 }')

       hcloud server create  --type "$size_slug" --location "$region" --image "$image_id" --name "$name" --ssh-key "$keyid" --poll-interval 250s 2>&1 >> /dev/null
       sleep 260
}

###################################################################
# deletes instance, if the second argument is set to "true", will not prompt
# used by axiom-rm
#
delete_instance() {
    name="$1"
    force="$2"
    id="$(instance_id "$name")"

    if [ "$force" != "true" ]; then
        read -p "Are you sure you want to delete instance '$name'? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Instance deletion aborted."
            return 1
        fi
    fi

    echo "Deleting instance '$name' with ID: $id"
    hcloud server delete "$id"
}

###################################################################
# Instances functions
# used by many functions in this file
#
# takes no arguments, outputs JSON object with instances
instances() {
	hcloud server list -o json
}

# takes one argument, name of instance, returns raw IP address
# used by axiom-ls axiom-init
instance_ip() {
	name="$1"
	instances | jq ".[] | select(.name ==\"$name\") | .public_net.ipv4.ip"
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
  #number of servers
  servers=$(echo $data | jq -r '.[]|.id' | wc -l)
  #default size from config file
  type="$(jq -r .default_size "$AXIOM_PATH/axiom.json")"
  #monthly price of server type 
  price=$(hcloud server-type list -o json | jq -r ".[] | select(.name == \"$type\") | .prices[0].price_monthly.net")
  totalPrice=$(echo "$price * $servers" | bc)
  header="Instance,Primary Ip,Region,Memory,Status,\$/M"
  totals="_,_,Instances,$servers,Total,\$$totalPrice"
  fields=".[] | [.name, .public_net.ipv4.ip, .datacenter.location.name, .server_type.memory, .status, \"$price\"] | @csv"

  # Printing part
  # sort -k1 sorts all data by label/instance/server name
  (echo "$header" && echo "$data" | jq -r "$fields" | sort -k1 && echo "$totals") | sed 's/"//g' | column -t -s,
}

###################################################################
#  Dynamically generates axiom's SSH config based on your cloud inventory
#  Choose between generating the sshconfig using private IP details, public IP details or optionally lock
#  Lock will never generate an SSH config and only used the cached config ~/.axiom/.sshconfig 
#  Used for axiom-exec axiom-fleet axiom-ssh
#
# Generate SSH config specfied in generate_sshconfig key:value in account.json
#
generate_sshconfig() {
accounts=$(ls -l "$AXIOM_PATH/accounts/" | grep "json" | grep -v 'total ' | awk '{ print $9 }' | sed 's/\.json//g')
current=$(ls -lh "$AXIOM_PATH/axiom.json" | awk '{ print $11 }' | tr '/' '\n' | grep json | sed 's/\.json//g') > /dev/null 2>&1
droplets="$(instances)"
sshnew="$AXIOM_PATH/.sshconfig.new$RANDOM"
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
 ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .private_net.ipv4.ip")
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
 ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .public_net.ipv4.ip")
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
        images=$(hcloud image list -o json)
        if [[ $query == "$1" ]]; then
                id=$(echo $images |  jq -r ".[] | select((.description==\"$query\") and (.architecture==\"x86\")) | .id")
        else
        id=$(echo $images |  jq -r ".[] | select((.name==\"$query\") and (.architecture==\"x86\")) | .id")
        fi
        echo $id
}


###################################################################
# Manage snapshots
# used for axiom-images
#
# get JSON data for snapshots
snapshots() {
        hcloud image list -t snapshot -o json
}

# only displays private images
# axiom-images
snapshots() {
        hcloud image list -t snapshot -o json
}

get_snapshots()
{
        hcloud image list -t snapshot
}

# Delete a snapshot by its name
# axiom-images
delete_snapshot() {
        name="$1"
        hcloud image delete "$(get_image_id $1)"
}


# axiom-images
create_snapshot() {
        instance="$1"
	snapshot_name="$2"
        hcloud server create-image  --type snapshot $instance --description $snapshot_name
}

###################################################################
# Get data about regions
# used by axiom-regions
list_regions() {
    hcloud location list
}

# used for axiom-region
regions() {
    hcloud location list -o json | jq -r '.[].name'
}

###################################################################
#  Manage power state of instances
#  Used for axiom-power
#
poweron() {
    instance_name="$1"
    hcloud server poweron $(instance_id $instance_name)
}

# axiom-power
poweroff() {
    instance_name="$1"
    hcloud server shutdown $(instance_id $instance_name)
}

# axiom-power
reboot(){
    instance_name="$1"
    hcloud server reboot $(instance_id $instance_name)
}

# axiom-power axiom-images
instance_id() {
        name="$1"
        instances | jq ".[] | select(.name ==\"$name\") | .id"
}

###################################################################
#  List available instance sizes
#  Used by ax sizes
#
sizes_list() {
hcloud server-type list --output json | jq -r '
  ["ID", "Name", "Description", "Cores", "Memory (GB)", "Disk (GB)", "Storage Type", "CPU Type", "Architecture", "Price (€/Month)", "Price (€/Hour)", "Price per TB Traffic (€/TB)"],
  (.[]
  | [
      .id,
      .name,
      .description,
      .cores,
      .memory,
      .disk,
      .storage_type,
      .cpu_type,
      .architecture,
      (.prices[0].price_monthly.net | tonumber),
      (.prices[0].price_hourly.net | tonumber),
      (.prices[0].price_per_tb_traffic.net | tonumber)
    ]) | @tsv
' | iconv -c -t UTF-8 | column -t -s $'\t'
}
