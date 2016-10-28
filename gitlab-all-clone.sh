#!/bin/bash
set -eu

. gitlab-all-clone.config

get_projects() {
	echo "get projects"
	local pages=$(curl -s --head --header "PRIVATE-TOKEN: $GLAC_PRIVATE_TOKEN" $GLAC_URL/api/v3/projects | perl -nle 'if(/^X-Total-Pages: (\d+)/){ print $1 }' )

	rm -f projects.tmp

	local ct=0
	while [ $ct -lt $pages ]; do
		ct=$(( ct + 1 ))
		curl -s --header "PRIVATE-TOKEN: $GLAC_PRIVATE_TOKEN" $GLAC_URL/api/v3/projects?page=$ct | jq -r '.[].path_with_namespace' >> projects.tmp
	done

	cat projects.tmp | sort > projects.txt
	rm projects.tmp
}
get_projects

get_repos() {
	local i
	mkdir -p $GLAC_DIR
	cd $GLAC_DIR
	for i in $(cat ../projects.txt); do
		local glgroup=$(echo "$i" | cut -d '/' -f1)
		local glname=$(echo "$i" | cut -d '/' -f2)

		echo "*** Group:$glgroup Name:$glname***"

		mkdir -p $glgroup
		cd $glgroup
		git clone $GLAC_SSH:$glgroup/$glname.git
		cd $glname
		git config user.name $GLAC_USERNAME
		git config user.email $GLAC_EMAIL
		cd ../..

		echo ""

	done
	cd ..
}
get_repos

