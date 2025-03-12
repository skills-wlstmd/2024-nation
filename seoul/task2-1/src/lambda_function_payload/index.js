const AWS = require('aws-sdk');
const Sharp = require('sharp');
const S3 = new AWS.S3({ region: 'us-east-1' }); // 리전 설정

async function getBucketNamesWithPrefix() {
  const prefix = 'wsi-static-';
  const data = await S3.listBuckets().promise();
  const buckets = data.Buckets.filter(bucket => bucket.Name.startsWith(prefix));
  return buckets.map(bucket => bucket.Name);
}

exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const params = request.querystring.split('&').reduce((acc, item) => {
        const [key, value] = item.split('=');
        acc[key] = value;
        return acc;
    }, {});
    
    const { width, height } = params;
    
    const bucketNames = await getBucketNamesWithPrefix();
    const BUCKET = bucketNames[0];
    
    const key = decodeURIComponent(request.uri.substring(1)); // 이미지 파일의 S3 키
    const widthInt = parseInt(width, 10);
    const heightInt = parseInt(height, 10);
    
    if (!widthInt || !heightInt) {
        return {
            status: '400',
            statusDescription: 'Bad Request',
            body: 'Invalid width or height parameter',
        };
    }
    
    try {
        const s3Object = await S3.getObject({ Bucket: BUCKET, Key: key }).promise();
        const resizedImage = await Sharp(s3Object.Body)
            .resize(widthInt, heightInt, {
                fit: 'fill' // 자르지 않고 축소
            })
            .toBuffer();

        return {
            status: '200',
            statusDescription: 'OK',
            body: resizedImage.toString('base64'),
            bodyEncoding: 'base64',
            headers: {
                'content-type': [{ key: 'Content-Type', value: 'image/jpeg' }],
                'cache-control': [{ key: 'Cache-Control', value: 'max-age=86400' }],
            },
        };
    } catch (error) {
        console.error('Error processing image:', error);
        return {
            status: '500',
            statusDescription: 'Internal Server Error',
            body: 'Error processing image',
        };
    }
};