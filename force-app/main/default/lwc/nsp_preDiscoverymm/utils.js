const constructArray = function(obj){
    return Object.keys(obj).map(name => { return { name, label: obj[name]} })
}

const getUpdatedFieldVisibility = function(fieldConfig, value){
    const fieldVisibility = {};

    fieldConfig.forEach(({ expValue, dependentFields }) => {
        dependentFields.forEach(field => {
            if(Array.isArray(value)) {
                let isVisible = false;
                value.forEach(val => {
                    if(expValue.includes(val)){
                        isVisible = true;
                    }
                });
                if(!(field in fieldVisibility) || (isVisible && !fieldVisibility[field])){
                    fieldVisibility[field] = isVisible;
                }
            } else{
                const isVisible = expValue.includes(value);
                if(!(field in fieldVisibility) || (isVisible && !fieldVisibility[field])){
                    fieldVisibility[field] = isVisible;
                }
            }
        });
    });

    return fieldVisibility;
}
const getFieldHierarchy = function(mapping) {
    const fieldHierarchy = {};

    Object.keys(mapping).forEach(fieldName => {
        if(!(fieldName in fieldHierarchy)){
            fieldHierarchy[fieldName] = 0;
        }

        const childOrder = fieldHierarchy[fieldName] + 1;

        mapping[fieldName].forEach(({ dependentFields }) => {
            dependentFields.forEach(dependentField => {
                fieldHierarchy[dependentField] = childOrder;
            });
        })
    });

    return fieldHierarchy;
}

const debounce = function(func, delay = 0) {
    let timer;
    return function (...args) {
        clearTimeout(timer);
        timer = setTimeout(() => {
            func.apply(this, args);
        }, delay);
    };
}

export { constructArray, getUpdatedFieldVisibility, debounce, getFieldHierarchy }