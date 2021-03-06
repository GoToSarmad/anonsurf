import random
import strutils
import osproc

randomize()


proc generatePassword*(): string =
  #[
    Generate random string
  ]#
  let randLen = rand(8..16)
  var password = ""
  for i in 0.. randLen:
    password = password & sample(strutils.Letters)

  return password


proc generateHash*(password: string): string =
  #[
    Generate tor hash by calling tor command
  ]#
  let output = execProcess("tor --hash-password \"" & password & "\"")
  # The hash is usually at the end of list
  # all other lines are comments
  # We do for loop to make sure there is no mistake
  for line in output.split("\n"):
    if line.startsWith("16:"):
      return line

proc genBridgeAddr*(): string =
  #[
    Read the list from official list
    Random selecting from the list
  ]#
  const
    basePath = "/etc/anonsurf/obfs4bridge.list" # TODO change here. Development only

  var
    allBridgeAddr: seq[string]

  for line in lines(basePath):
    if not line.startsWith("#") and not isEmptyOrWhitespace(line):
      allBridgeAddr.add(line)
  
  return sample(allBridgeAddr)


proc genTorrc*(hashed: string, isTorBridge: bool = false): string =
  #[
    Generate final torrc file
  ]#
  const
    basePath = "/etc/anonsurf/torrc.base"

  result = readFile(basePath)
  result &= "\nHashedControlPassword " & hashed & "\n"

  if isTorBridge == true:
    # https://sigvids.gitlab.io/create-tor-private-obfs4-bridges.html
    # https://community.torproject.org/relay/setup/bridge/debian-ubuntu/
    result &= "#Bridge config\nUseBridges 1\nBridgeRelay 1\nExtORPort auto\n"
    result &= "ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy managed\nORPort 9001\nServerTransportListenAddr obfs4 127.0.0.1:9443\n" # TODO check here Security reason
    result &= "Bridge " & genBridgeAddr() & "\n"
    # result &= "ServerTransportListenAddr obfs4 0.0.0.0:9443\n" # TODO check here. Security reason
    # TODO ServerTransportListenAddr obfs4 0.0.0.0:TODO2
