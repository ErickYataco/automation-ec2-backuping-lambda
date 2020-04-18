const AWS = require('aws-sdk')
const EC2 = new AWS.EC2()

exports.handler = async (event, context) => {

    let instances   =[]
    let regions     =[]

    try {

        const hour = new Date(new Date().toLocaleString("en-US", {timeZone:process.env.TIME_ZONE})).getHours()

        regions = await EC2.describeRegions().promise()
        let region

        for (region of regions.Regions){
            let ec2 = new AWS.EC2({region: region.RegionName})
            let instance, volume, snapShot, des
            
            instances = await ec2.describeInstances().promise()

            if (instances.Reservations.length>0){
                for ( instance of instances.Reservations[0].Instances) {
                    for (volume of instance.BlockDeviceMappings){
                        des = "bakup instance "+instance.InstanceId+", volume "+volume.Ebs.VolumeId+", created "+Date()
                        console.log(des) 
                        snapShot =  ec2.createSnapshot({VolumeId:volume.Ebs.VolumeId, Description: des}).promise() 
                        console.log("Created snapshot ",snapShot)  
                    }
                }
            }
    
        }

        return true

    } catch (error) {

        console.log('error: ',error)
        return false

    }

}