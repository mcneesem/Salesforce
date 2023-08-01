const OBJECT_DATA_TYPE_NAME = 'object';

const isObject = function(val){
    return val && typeof val === OBJECT_DATA_TYPE_NAME && !Array.isArray(val);
}

export { isObject };