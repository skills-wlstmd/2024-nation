async function handler(event) {
    const request = event.request;
    // const host = event.context.distributionDomainName;
    const uri = request.uri;
    
    if (uri === '/index.html' || uri.startsWith('/images')) {
        return request;
    }
    
    return {
        statusCode: 302,
        statusDescription: 'Found',
        headers: { 
            "location": { 
                "value": `/index.html` 
            }
        }
    }
}