import argparse
import patreon
import json
import hashlib

parser = argparse.ArgumentParser(description="Just an example",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("creator_id_key", help="Patreon API key")
args = parser.parse_args()
config = vars(args)
print(args.creator_id_key)

api_client = patreon.API(args.creator_id_key)
print(api_client.get_campaigns(2500))
campaign_id = api_client.get_campaigns(2500).data()[0].id()
pledges_response = api_client.get_campaigns_by_id_members(
    campaign_id,
    2500,
    None,
    ["currently_entitled_tiers"],
    {
        "member": ["full_name", "lifetime_support_cents"]
    }
)

replacements = json.load(open('patreon_replacements.json'))["replacements"]

def get_names(all_pledges, out_data):
    for pledge in all_pledges:
        hashed_id = hashlib.sha1(pledge.id().encode('utf-8')).hexdigest()
        print(hashed_id, pledge.attribute('full_name'))
        member_data = {
            "name": "",
            "lifetime_support_cents": ""
        }
        if hashed_id in replacements:
            member_data["name"] = replacements[hashed_id]["full_name"]
        else:
            member_data["name"] = pledge.attribute('full_name')
        member_data["lifetime_support_cents"] = pledge.attribute('lifetime_support_cents')
        out_data.append(member_data)
supporter_data = []
get_names(pledges_response.data(), supporter_data)

with open("patrons.gd", "w") as outfile:
    outfile.write("const PATRONS = [\n")
    for supporter in supporter_data:
        if supporter["lifetime_support_cents"] > 0:
            outfile.write(f"  \"{supporter["name"]}\",\n")
        else:
            print(f"Skipping {supporter["name"]} since they never gave us money...")
    outfile.write("]\n")
    #json.dump(out_dict, outfile)