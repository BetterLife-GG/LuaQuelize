const mysql2 = require('mysql2');

const mysql_slow_query_warning = GetConvarInt('mysql_slow_query_warning', 200);
const mysql_connection_string = GetConvar('mysql_connection_string', '');

const parseUri = (connectionString) => {
  const splitMatchGroups = connectionString.match(
    new RegExp(
      '^(?:([^:/?#.]+):)?(?://(?:([^/?#]*)@)?([\\w\\d\\-\\u0100-\\uffff.%]*)(?::([0-9]+))?)?([^?#]+)?(?:\\?([^#]*))?$'
    )
  );

  if (!splitMatchGroups)
    throw new Error(
      `mysql_connection_string structure was invalid (${connectionString})`
    );

  const authTarget = splitMatchGroups[2] ? splitMatchGroups[2].split(':') : [];

  const options = {
    user: authTarget[0] || undefined,
    password: authTarget[1] || undefined,
    host: splitMatchGroups[3],
    port: parseInt(splitMatchGroups[4]),
  };

  return options;
};

const mysql_transaction_isolation_level = (() => {
  const query = 'SET TRANSACTION ISOLATION LEVEL';
  switch (GetConvarInt('mysql_transaction_isolation_level', 2)) {
    case 1:
      return `${query} REPEATABLE READ`;
    case 2:
      return `${query} READ COMMITTED`;
    case 3:
      return `${query} READ UNCOMMITTED`;
    case 4:
      return `${query} SERIALIZABLE`;
    default:
      return `${query} READ COMMITTED`;
  }
})();

const connectionOptions = (() => {
  const options = mysql_connection_string.includes('mysql://')
    ? parseUri(mysql_connection_string)
    : mysql_connection_string
        .replace(
          /(?:host(?:name)|ip|server|data\s?source|addr(?:ess)?)=/gi,
          'host='
        )
        .replace(/(?:user\s?(?:id|name)?|uid)=/gi, 'user=')
        .replace(/(?:pwd|pass)=/gi, 'password=')
        .replace(/(?:db)=/gi, 'database=')
        .split(';')
        .reduce((connectionInfo, parameter) => {
          const [key, value] = parameter.split('=');
          connectionInfo[key] = value;
          return connectionInfo;
        }, {});

  options.namedPlaceholders =
    options.namedPlaceholders === 'false' ? false : true;

  for (const key in options) {
    const value = options[key];

    if (typeof value === 'string') {
      try {
        options[key] = JSON.parse(value);
        console.log(key, options[key]);
      } catch {}
    }
  }

  return options;
})();

let pool;
let serverReady = false;

setTimeout(() => {
  pool = mysql2.createPool({
    connectTimeout: 60000,
    trace: false,
    supportBigNumbers: true,
    ...connectionOptions,
    // typeCast,
  });

  pool.query(mysql_transaction_isolation_level, (err) => {
    if (err)
      return console.error(
        `^3Unable to establish a connection to the database!\n^3[${err}]^0`
      );
    console.log(`^2Database server connection established!^0`);
    serverReady = true;
  });
});

const scheduleTick = async () => {
  if (!serverReady) {
    await new Promise((resolve) => {
      (function wait() {
        console.log(serverReady);
        if (serverReady) {
          return resolve();
        }
        setTimeout(wait);
      })();
    });
  }

  // ScheduleResourceTick(resourceName);
};

const rawQuery = async (query) => {
  await scheduleTick();

  return await new Promise(async (resolve, reject) => {
    pool.query(query, (err, results) => {
      if (err) return reject(err);
      resolve(results);
    });
  });
};

const MySQL = {
  query: rawQuery,
};

for (const key in MySQL) {
  global.exports(key, MySQL[key]);
}
