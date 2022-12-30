const express = require('express')
const fetch = require('node-fetch');
const app = express()
const port = 3000

//https://dummyjson.com/products/1
app.get('/', async (req, res) => {
  const dueResponse = await fetch(`${process.env.DUE_SERVICE_API_BASE}:3000`)
  const treResponse = await fetch(`${process.env.TRE_SERVICE_API_BASE}:3000`)
  const dueData = await dueResponse.json();
  const treData = await treResponse.json();
  res.json({
    msg: "Hello world! (from uno)",
    due:{
      url: process.env.DUE_SERVICE_API_BASE,
      data: dueData,
    },
    uno:{
      url: process.env.TRE_SERVICE_API_BASE,
      data: treData,
    }
  })
})

app.get('/healthcheck', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})