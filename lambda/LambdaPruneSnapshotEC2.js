const AWS = require('aws-sdk')
const EC2 = new AWS.EC2()
const sts = new AWS.STS();


exports.handler = async (event, context) => {

    var snapshots   =[]
    var regions     =[]

    try {

        var identity = await sts.getCallerIdentity().promise()
        regions = await EC2.describeRegions().promise()
        var region

        for (region of regions.Regions){

            var ec2 = new AWS.EC2({region: region.RegionName})
            var snapshot, result

            snapshots = await ec2.describeSnapshots({OwnerIds: [ identity.Account ]}).promise()
            snapshots.Snapshots.sort((a, b) => (a.StartTime > b.StartTime) ? 1 : -1)            
            snapshots = snapshots.Snapshots.slice(0,3)
            
            for(snapshot of snapshots){
                console.log("snapshot ",snapshot)
                result = await ec2.deleteSnapshot({SnapshotId: snapshot.SnapshotId}).promise()
            }
        }

        return true

    } catch (error) {

        console.log('error: ',error)
        return false

    }

}