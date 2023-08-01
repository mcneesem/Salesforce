const prepareMapByValue = function (arr) {
  const map = {};
  arr.forEach((elm) => {
    if (elm.value) {
      map[elm.value] = elm;
    }
  });

  return map;
};

export { prepareMapByValue };
