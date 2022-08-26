import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import marketplaceAbi from '../contract/marketplace.abi.json'
import erc20Abi from "../contract/erc20.abi.json"


const ERC20_DECIMALS = 18
const MPContractAddress = "0x6257F57569e1e65A651E89e86ACb9fB4069581Eb"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

let kit
let contract
let houses = []

const connectCeloWallet = async function () {
  if (window.celo) {
    notification("⚠️ Please approve HusHousing DApp to gain access...")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}


const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}

const getHouses = async function() {
  const _numberOfHousesAvailable = await contract.methods.viewNumberOfHouseAvailable().call()
  const _houses = []

  for (let i = 0; i < _numberOfHousesAvailable; i++) {
    let _house = new Promise(async (resolve, reject) => {
      let p = await contract.methods.viewHouse(i).call()
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        location: p[4],
        price: new BigNumber(p[5]),
        sold:p[6],
      })
    })
    _houses.push(_house)
  }
  houses = await Promise.all(_houses)
  renderHouses()
}


function renderHouses() {
  document.getElementById("marketplace").innerHTML = ""
  houses.forEach((_house) => {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-4"
    newDiv.innerHTML = houseTemplate(_house)
    document.getElementById("marketplace").appendChild(newDiv)
  })
}



function houseTemplate(_house) {
  return `
    <div class="card mb-4">
      <img class="card-img-top" src="${_house.image}" alt="...">
      <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_house.owner)}
        </div>
        <h2 class="card-title fs-4 fw-bold mt-2">${_house.name}</h2>
        <p class="card-text mb-4" style="min-height: 82px">
          ${_house.description}             
        </p>
        <p class="card-text mt-4">
          <i class="bi bi-geo-alt-fill"></i>
          <span>${_house.location}</span>
        </p>
        ${(_house.owner === kit.defaultAccount) && (_house.sold === false)  ? `<div class="d-grid gap-2">
        <a class="btn btn-lg btn-outline-dark cancelSaleBtn fs-6 p-3"  id=${_house.index} >
          Cancel Sale 
        </a>
      </div>`
          :
          _house.owner === kit.defaultAccount ? `<div class="d-grid gap-2">
        <a class="btn btn-lg btn-outline-dark resellBtn fs-6 p-3"  id=${_house.index} >
          Resell 
        </a>
      </div>`
       :
          `<div class="d-grid gap-2">
              <a class="btn btn-lg btn-outline-success buyBtn fs-6 p-3" id=${
                _house.index
              }>
                Buy for ${_house.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
              </a>
            </div>`
        }
      </div>
    </div>
  `
}


function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}

function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}


window.addEventListener('load', async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getHouses()
  notificationOff()
});


document
  .querySelector("#newHouseBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newHouseName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newHouseDescription").value,
      document.getElementById("newLocation").value,
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString()
    ]
    notification(`⌛ Adding "${params[0]}"...`)
    try {
      const result = await contract.methods
        .addHouse(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`🎉 You successfully added "${params[0]}". 🎉`)
    getHouses()
  })


 document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("buyBtn")) {
    const index = e.target.id
    notification("⌛ Waiting for payment approval...")
    try {
      await approve(houses[index].price)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`⌛ Awaiting payment for "${houses[index].name}"...`)
    try {
      const result = await contract.methods
        .buyHouse(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully bought "${houses[index].name}". 🎉`)
      getHouses()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }


  if (e.target.className.includes("resellBtn")) {
    const index = e.target.id
    let price = prompt(`Enter new price for "${houses[index].name} (cUSD) ":`)
    if (price != null) {
      price= new BigNumber(price)
      notification(`⌛ Reselling "${houses[index].name}"...`)
      try {
        const result = await contract.methods
          .reSellHouse(index,price)
          .send({ from: kit.defaultAccount })
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
      notification(`🎉 You successfully resold "${houses[index].name}". 🎉`)
      getHouses()
      getBalance() 
    }
    else {
      alert("⚠️ You must enter a price.")
    }
  }

  if (e.target.className.includes("cancelSaleBtn")) {
    const index = e.target.id
    notification("⌛ Waiting for abort-sale approval...")
    try {
      await approve(houses[index].price)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`⌛ Aborting sale of "${houses[index].name}"...`)
    try {
      const result = await contract.methods
        .cancelSale(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 Cancelling sale of "${houses[index].name}" successful. 🎉`)
      getHouses()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
})
