import argparse
import patreon
import json
import hashlib

parser = argparse.ArgumentParser(description="Just an example",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("creator_id_key", help="Patreon API key")
args = parser.parse_args()
config = vars(args)

api_client = patreon.API(args.creator_id_key)
campaign_id = api_client.get_campaigns(2500).data()[0].id()
pledges_response = api_client.get_campaigns_by_id_members(
    campaign_id,
    2500,
    None,
    ["currently_entitled_tiers"],
    {
        "member": ["full_name"]
    }
)

replacements = json.load(open('patreon_replacements.json'))["replacements"]

def get_names(all_pledges, names):
    for pledge in all_pledges:
        hashed_id = hashlib.sha1(pledge.id().encode('utf-8')).hexdigest()
        print(hashed_id, pledge.attribute('full_name'))
        if hashed_id in replacements:
            names.append(replacements[hashed_id]["full_name"])
        else:
            names.append(pledge.attribute('full_name'))

names = []
get_names(pledges_response.data(), names)

out_dict = {
    "patrons": names
}

with open("patrons.gd", "w") as outfile:
    outfile.write("const PATRONS = [\n")
    for name in names:
        outfile.write(f"  \"{name}\",\n")
    outfile.write("]\n")
    #json.dump(out_dict, outfile)