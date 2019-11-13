import { APIGatewayProxyHandler } from 'aws-lambda';
import fetch from 'node-fetch';

interface QueryStringParams {
  i?: string;
  t?: string;
  s?: string;
  type?: string;
  y?: number;
  plot?: string;
  r?: string;
  callback?: Function;
  v?: number;
}

function processQueryStringParams(params: QueryStringParams): string {
  return Object.keys(params).reduce((accum, current) => {
    return `${accum}&${current}=${encodeURIComponent(params[current])}`;
  }, '');
};

export const handler: APIGatewayProxyHandler  = async (event) => {
  const key = process.env.OMDB_KEY;
  let data;

  try {
    const params: QueryStringParams = event.queryStringParameters;
    const url = `http://www.omdbapi.com/?apikey=${key}${processQueryStringParams(params)}`;
    const apiResponse = await fetch(url);
    data = await apiResponse.json();
  } catch(error) {
    console.error(error);
  }

  return {
    statusCode: 200,
    body: JSON.stringify(data),
  };
}
