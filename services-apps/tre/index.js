const express = require('express')
const fetch = require('node-fetch');
const app = express()
const port = 3000

//https://dummyjson.com/products/1
app.get('/', (req, res) => {
  res.json({
    msg: "Hello world! (from tre)",
  })
})
app.get('/healthcheck', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})