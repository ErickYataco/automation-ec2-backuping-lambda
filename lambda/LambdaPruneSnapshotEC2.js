const AWS = require('aws-sdk')
const EC2 = new AWS.EC2()

exports.handler = async (event, context) => {

    var instances   =[]
    var regions     =[]

    try {

        var hour = new Date(new Date().toLocaleString("en-US", {timeZone:process.env.TIME_ZONE})).getHours()

        regions = await EC2.describeRegions().promise()
        var region

        for (region of regions.Regions){
            var ec2 = new AWS.EC2({region: region.RegionName})
            
            instances = await ec2.describeInstances(params).promise()
            var instance, snapShot, des

            if (instances.Reservations.length>0){
                for ( instance of instances.Reservations[0].Instances) {    
                    des = "bakup instance ${}, volume ${}, created ${}"                
                    snapShot =  ec2.createSnapshot({VolumeId:instance.VolumeId, Description: des}).promise() 
                    console.log("Created snapshot ",snapShot.id)
                }
            }
    
        }

        return true

    } catch (error) {

        console.log('error: ',error)
        return false

    }

}